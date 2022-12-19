import 'dart:async';

import 'package:faunadb_data/faunadb_data.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:localstorage/localstorage.dart';
import 'package:order_management/constants.dart';
import 'package:order_management/dispatched.dart';
import 'package:order_management/models/order.dart';
import 'package:order_management/users.dart';
import 'package:order_management/utils.dart';
import 'package:order_management/widgets/DateTimePicker.dart';

import 'deadline.dart';
import 'models/user.dart';
import 'orders.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final companyNameController = TextEditingController();
  final orderDetailsController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final searchController = TextEditingController();

  final orderRepository = OrderRepository();
  final userRepository = UserRepository();

  final orderStream = StreamController<Map<EventType, dynamic>>.broadcast();
  final localStorage = LocalStorage(localStorageKey);

  final _formKey = GlobalKey<FormState>();

  DateTime deadlineDate = DateTime.now();
  bool isSearching = false;
  final Map<String, Order> orders = {};
  final Map<String, User> users = {};
  User? user;
  Timer? _debounce;
  late Animation<double> animation;
  late AnimationController controller;

  void getUser() async {
    await localStorage.ready;
    final userJson = localStorage.getItem('user');
    if (userJson != null) {
      final user = getUserFromJson(userJson);
      setState(() {
        this.user = user;
      });
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  void postSubmit(Order order, Order? orderArg) {
    setState(() {
      companyNameController.clear();
      orderDetailsController.clear();
      if (orderArg != null) {
        orderStream.add({EventType.search: ""});
      } else {
        orderStream.add({EventType.orderAdded: order});
      }
    });
    Fluttertoast.showToast(msg: 'Order ${orderArg != null ? "Updated" : "Added"} successfully');
  }

  @override
  void initState() {
    getUser();

    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    animation = Tween<double>(begin: 0, end: 300).animate(controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {});

    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1000), () {
        orderStream.add({EventType.search: searchController.text});
      });
    });

    super.initState();
  }

  void decideModal(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Choose an option'),
            content: const Text('What do you want to do?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openUserModal();
                },
                child: const Text('Add user'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openOrderModal(null);
                },
                child: const Text('Add Order'),
              ),
            ],
          );
        });
  }

  void openUserModal() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return SimpleDialog(
                contentPadding: const EdgeInsets.all(20),
                title: const Text('Add User'),
                children: [
                  Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Name',
                            ),
                            controller: nameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),
                          const Padding(padding: EdgeInsets.all(10)),
                          TextFormField(
                              controller: passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Password',
                              )),
                          const Padding(padding: EdgeInsets.all(10)),
                        ],
                      )),
                  ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final newUser = await createUser(
                              userRepository,
                              UserType.factory,
                              nameController.text,
                              passwordController.text);
                          if (!mounted) return;
                          Navigator.pop(context);
                          if (newUser != null) {
                            Fluttertoast.showToast(
                                msg: 'User added successfully');
                            setState(() {
                              passwordController.clear();
                              orderStream.add({EventType.userAdded: newUser});
                            });
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Failed to create user');
                          }
                        }
                      },
                      child: const Text("Submit"))
                ]);
          });
        });
  }

  void openOrderModal(Order? orderArg) {
    if (orderArg != null) {
      companyNameController.text = orderArg.companyName;
      orderDetailsController.text = orderArg.orderDetails;
      deadlineDate = DateTime.parse(orderArg.deadline);
    }
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return SimpleDialog(
                contentPadding: const EdgeInsets.all(20),
                title: const Text('Add Order'),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Company Name',
                          ),
                          controller: companyNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a company name';
                            }
                            return null;
                          },
                        ),
                        const Padding(padding: EdgeInsets.all(10)),
                        TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Order Details',
                          ),
                          keyboardType: TextInputType.multiline,
                          maxLines: 10,
                          controller: orderDetailsController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter order details';
                            }
                            return null;
                          },
                        ),
                        const Padding(padding: EdgeInsets.all(10)),
                      ],
                    ),
                  ),
                  // add date picker widget
                  DateTimePicker(
                      labelText: "Deadline Date",
                      selectedDate: deadlineDate,
                      selectedTime: TimeOfDay.now(),
                      selectDate: (DateTime date) {
                        setState(() {
                          deadlineDate = date;
                        });
                      },
                      selectTime: (TimeOfDay time) {}),

                  const Padding(padding: EdgeInsets.all(10)),
                  ElevatedButton(
                    onPressed: () async {
                      // save order
                      final id = await orderRepository.nextId();
                      if (id.isPresent && _formKey.currentState!.validate()) {
                        try {
                          final order = await orderRepository.save(
                              Order(
                                  orderArg?.id ?? id.value,
                                  companyNameController.text,
                                  orderDetailsController.text,
                                  orderArg?.orderStatus ?? 'Pending',
                                  deadlineDate.toIso8601String(),
                                  DateTime.now().toIso8601String()),
                              getOrderFromJson);

                          // add order to stream
                          if (!mounted) return;
                          Navigator.pop(context);
                          postSubmit(order, orderArg);
                        } on FaunaDbException catch (e) {
                          Fluttertoast.showToast(
                              msg: "Error: ${e.cause}",
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        }
                      } else {
                        setState(() {
                          companyNameController.clear();
                          orderDetailsController.clear();
                        });
                        // show a error toast
                        Fluttertoast.showToast(
                            msg: 'Error while saving order',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.red,
                            fontSize: 16.0);
                      }
                    },
                    child: const Text('Submit'),
                  )
                ],
              );
            },
          );
        }).then((value) {
      setState(() {
        companyNameController.clear();
        orderDetailsController.clear();
        deadlineDate = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    companyNameController.dispose();
    orderDetailsController.dispose();
    orderStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userTab = user?.userType == UserType.shop
        ? [const Tab(icon: Icon(Icons.account_box), text: 'User')]
        : [];
    final length = user?.userType == UserType.shop ? 4 : 3;
    return DefaultTabController(
        length: length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: isSearching
                ? Container(
                    width: animation.value,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5)),
                    child: Center(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  controller.reverse();
                                  // wait 700 ms
                                  Future.delayed(
                                      const Duration(milliseconds: 700), () {
                                    setState(() {
                                      isSearching = false;
                                      orderStream.add({EventType.search: ""});
                                    });
                                  });
                                });
                                /* Clear the search field */
                              },
                            ),
                            hintText: 'Search...',
                            border: InputBorder.none),
                      ),
                    ),
                  )
                : Text(widget.title),
            actions: [
              PopupMenuButton(itemBuilder: (context) {
                final tabIndex = DefaultTabController.of(context)?.index;
                List<PopupMenuItem> menu = tabIndex == 0
                    ? [
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              orderStream
                                  .add({EventType.orderDispatched: orders});
                              //orders.clear();
                              Navigator.pop(context);
                            },
                            child: Row(
                              children: const [
                                Icon(Icons.send),
                                Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text('Dispatch'),
                                )
                              ],
                            ),
                          ),
                        )
                      ]
                    : [];
                return [
                  PopupMenuItem(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          controller.forward();
                          isSearching = true;
                          Navigator.pop(context);
                        });
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.search),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Text('Search'),
                          )
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    child: TextButton(
                      onPressed: () {
                        if (orders.isNotEmpty) {
                          orderStream.add({EventType.orderDeleted: orders});
                        } else if (users.isNotEmpty) {
                          orderStream.add({EventType.userDeleted: users});
                        }
                        //orders.clear();
                        Navigator.pop(context);
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.delete_forever),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Text('Delete'),
                          )
                        ],
                      ),
                    ),
                  ),
                  ...menu,
                  PopupMenuItem(
                    child: TextButton(
                      onPressed: () async {
                        await localStorage.ready;
                        await localStorage.clear();

                        if (!mounted) {
                          return;
                        }
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.logout),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Text('Logout'),
                          )
                        ],
                      ),
                    ),
                  ),
                ];
              })
            ],
            bottom: TabBar(
              tabs: [
                const Tab(icon: Icon(Icons.book), text: 'Orders'),
                const Tab(icon: Icon(Icons.delivery_dining), text: 'Dispatch'),
                const Tab(
                    icon: Icon(Icons.calendar_month_sharp), text: 'Deadline'),
                ...userTab
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Orders(
                orderStream: orderStream,
                user: user,
                orders: orders,
                openModal: openOrderModal,
                orderRepository: orderRepository,
              ),
              Dispatched(
                orderRepository: orderRepository,
                orders: orders,
                openModal: openOrderModal,
                orderStream: orderStream,
              ),
              Deadline(
                orderRepository: orderRepository,
                orders: orders,
                openModal: openOrderModal,
                orderStream: orderStream,
              ),
              user?.userType == UserType.shop
                  ? Users(
                      userRepository: userRepository,
                      users: users,
                      userStream: orderStream,
                    )
                  : Container(),
            ],
          ),
          floatingActionButton: user?.userType == UserType.shop
              ? Wrap(
                  direction: Axis.horizontal,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        decideModal(context);
                      },
                      tooltip: 'Add Order',
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        orderStream.add({EventType.search: ""});
                      },
                      tooltip: 'Refresh',
                      child: const Icon(Icons.refresh),
                    )
                  ],
                )
              : FloatingActionButton(
                  onPressed: () {
                    orderStream.add({EventType.search: ""});
                  },
                  tooltip: 'Refresh',
                  child: const Icon(Icons.refresh),
                ), // This trailing comma makes auto-formatting nicer for build methods.
        ));
  }
}

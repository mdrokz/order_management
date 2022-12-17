import 'dart:async';

import 'package:faunadb_data/faunadb_data.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:order_management/constants.dart';
import 'package:order_management/dispatched.dart';
import 'package:order_management/models/order.dart';
import 'package:order_management/utils.dart';
import 'package:order_management/widgets/DateTimePicker.dart';

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
  final orderRepository = OrderRepository();
  final orderStream = StreamController<Map<EventType, dynamic>>.broadcast();
  final localStorage = LocalStorage(localStorageKey);
  DateTime deadlineDate = DateTime.now();
  bool isSearching = false;
  final Map<String, Order> orders = {};
  User? user;
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
    }
  }

  void postSubmit(Order order) {
    setState(() {
      companyNameController.clear();
      orderDetailsController.clear();
      orderStream.add({EventType.orderAdded: order});
    });
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

    super.initState();
  }

  void openOrderModal() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return SimpleDialog(
                contentPadding: const EdgeInsets.all(20),
                children: [
                  TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Company Name',
                      ),
                      controller: companyNameController),
                  const Padding(padding: EdgeInsets.all(10)),
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
                  const Padding(padding: EdgeInsets.all(5)),
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Order Details',
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: 10,
                    controller: orderDetailsController,
                  ),
                  const Padding(padding: EdgeInsets.all(10)),
                  ElevatedButton(
                    onPressed: () async {
                      // save order
                      final id = await orderRepository.nextId();
                      if (id.isPresent) {
                        try {
                          final order = await orderRepository.save(
                              Order(
                                  id.value,
                                  companyNameController.text,
                                  orderDetailsController.text,
                                  'Pending',
                                  DateFormat('MMMM d, y').format(deadlineDate),
                                  formatDate()),
                              getOrderFromJson);

                          // add order to stream
                          if(!mounted) return;
                          Navigator.pop(context);
                          postSubmit(order);
                          // setState(() {
                          //   companyNameController.clear();
                          //   orderDetailsController.clear();
                          //   orderStream.add({EventType.orderAdded: order});
                          // });
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
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
                    decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              controller.reverse();
                              // wait 700 ms
                              Future.delayed(const Duration(milliseconds: 700),
                                  () {
                                setState(() {
                                  isSearching = false;
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
                    orderStream
                        .add({EventType.orderDeleted: orders});
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
              PopupMenuItem(
                child: TextButton(
                  onPressed: () {},
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
              ),
              PopupMenuItem(
                child: TextButton(
                  onPressed: () async {
                    await localStorage.ready;
                    await localStorage.clear();

                    if (!mounted) {
                      return;
                    }
                    Navigator.pushNamed(context, '/login');
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
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.book), text: 'Orders'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Dispatched'),
            Tab(icon: Icon(Icons.date_range_outlined), text: 'Deadline')
          ],
        ),
      ),
      body: TabBarView(
        children: [
          Orders(
            orderStream: orderStream,
            user: user,
            orders: orders,
            orderRepository: orderRepository,
          ),
          Dispatched(orderRepository: orderRepository),
          Container()
        ],
      ),
      floatingActionButton: user?.userType == UserType.shop
          ? FloatingActionButton(
              onPressed: openOrderModal,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            )
          : null, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

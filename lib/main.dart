import 'dart:async';

import 'package:faunadb_data/faunadb_data.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:order_management/constants.dart';
import 'package:order_management/dispatched.dart';
import 'package:order_management/models/order.dart';
import 'package:order_management/utils.dart';

import 'orders.dart';

void main() {
  setCurrentUserDbKey(faunaKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const DefaultTabController(
          length: 2, child: MyHomePage(title: 'Order Management')),
    );
  }
}

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

class _MyHomePageState extends State<MyHomePage> {
  final companyNameController = TextEditingController();
  final orderDetailsController = TextEditingController();
  final orderRepository = OrderRepository();
  final orderStream = StreamController<Order>();

  void openOrderModal() {
    showDialog(
      context: context,
      builder: (context) {
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
                Navigator.pop(context);
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
                            formatDate()),
                        getOrderFromJson);

                    // add order to stream
                    setState(() {
                      companyNameController.clear();
                      orderDetailsController.clear();
                      orderStream.add(order);
                    });
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
        title: Text(widget.title),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.book), text: 'Orders'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Dispatched'),
          ],
        ),
      ),
      body: TabBarView(
        children: [Orders(orderStream: orderStream,orderRepository: orderRepository,), Dispatched(orderRepository: orderRepository)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openOrderModal,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

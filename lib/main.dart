import 'package:faunadb_data/faunadb_data.dart';
import 'package:flutter/material.dart';
import 'package:order_management/constants.dart';
import 'package:order_management/login.dart';

import 'home.dart';

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
      title: 'Order Management',
      initialRoute: '/login',
      routes: {
        '/': (context) => const MyHomePage(title: 'Order Management'),
        '/login': (context) => const LoginWrapper(),
      },
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
    );
  }
}



class LoginWrapper extends StatelessWidget {
  const LoginWrapper({Key? key}) : super(key: key);

  static const String _title = 'Order Management';
  @override
  Widget build(BuildContext context) {

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

      return Scaffold(
        appBar: AppBar(title: const Text(_title),automaticallyImplyLeading: false,centerTitle: true,),
        body: const Login(),
      );
  }
}

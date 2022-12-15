import 'dart:async';

import 'package:flutter/material.dart';
import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';
import 'package:order_management/utils.dart';

import 'constants.dart';
import 'models/order.dart';

class Orders extends StatefulWidget {
  const Orders(
      {Key? key, required this.orderStream, required this.orderRepository})
      : super(key: key);

  final StreamController<Order> orderStream;
  final OrderRepository orderRepository;

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final client = FaunaClient(
      FaunaConfig.build(secret: faunaKey));

  List<Order> orders = [];

  @override
  void initState() {
    if (!widget.orderStream.hasListener) {
      widget.orderStream.stream.listen((event) {
        setState(() {
          orders.add(event);
        });
      });
    }

    loadOrders();

    super.initState();
  }

  void loadOrders() async {
    final query = Map_(
        Paginate(Match(Index('dispatched_orders'), terms: ["Pending"])),
        Lambda("order", Get(Var("order"))));

    final result = await deserializeFauna<Order>(query, client, getOrderFromJson);

    setState(() {
      orders = result;
    });
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // add spinner if length is 0
    if (orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: IconButton(icon: const Icon(Icons.send,color: Colors.blue,),onPressed: () {
              order.orderStatus = "Dispatched";
              widget.orderRepository.save(order,getOrderFromJson);
              setState(() {
                orders.removeAt(index);
              });
            },),
            title: Text(order.companyName),
            subtitle: Text(order.orderDetails),
            trailing: IconButton(icon: const Icon(Icons.delete_forever,color: Colors.blue,),onPressed: () {
              widget.orderRepository.remove(order.id,getOrderFromJson);
              setState(() {
                orders.removeAt(index);
              });
            },),
          ),
        );
      },
    );
  }
}

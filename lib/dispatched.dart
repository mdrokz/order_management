import 'package:flutter/material.dart';
import 'package:order_management/utils.dart';

import 'constants.dart';
import 'models/order.dart';

import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';

class Dispatched extends StatefulWidget {
  const Dispatched({Key? key,required this.orderRepository}) : super(key: key);

  final OrderRepository orderRepository;


  @override
  _DispatchedState createState() => _DispatchedState();
}

class _DispatchedState extends State<Dispatched> {

  final client = FaunaClient(FaunaConfig.build(secret: faunaKey));

  List<Order> orders = [];

  @override
  void initState() {
    loadOrders();
    super.initState();
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  void loadOrders() async {
    final query = Map_(Paginate(Match(Index('dispatched_orders'),terms: ["Dispatched"])),Lambda("order",Get(Var("order"))));

    final result = await deserializeFauna<Order>(query, client, getOrderFromJson);

    setState(() {
      orders = result;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            contentPadding: const EdgeInsets.all(2),
            title: Text(order.companyName),
            subtitle: Text(order.orderDetails),
            trailing: Text(order.orderStatus),
          ),
        );
      },
    );
  }
}
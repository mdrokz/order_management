import 'dart:async';

import 'package:flutter/material.dart';
import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';
import 'package:order_management/utils.dart';

import 'constants.dart';
import 'models/order.dart';
import 'models/user.dart';

class Orders extends StatefulWidget {
  const Orders(
      {Key? key,
      required this.orderStream,
      required this.orders,
      required this.user,
      required this.orderRepository})
      : super(key: key);

  final StreamController<Map<EventType, dynamic>> orderStream;
  final User? user;
  final Map<String, Order> orders;
  final OrderRepository orderRepository;

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final client = FaunaClient(FaunaConfig.build(secret: faunaKey));

  StreamSubscription<Map<EventType, dynamic>>? streamSubscription;

  bool isLoading = false;

  List<Order> orders = [];

  @override
  void initState() {
    if (mounted) {
      setState(() {
        streamSubscription = widget.orderStream.stream.listen((event) async {
          final key = event.keys.first;
          final value = event.values.first;
          switch (key) {
            case EventType.orderAdded:
              if (value is Order) {
                setState(() {
                  orders.add(value);
                });
              }
              break;
            case EventType.orderDeleted:
              if (value is Map<String, Order>) {
                setState(() {
                  orders.removeWhere((element) {
                    if (value.containsKey(element.id)) {
                      widget.orderRepository
                          .remove(element.id, getOrderFromJson);
                      return true;
                    }
                    return false;
                  });
                });
              }
              break;
            case EventType.orderDispatched:
              if (value is String) {
                final order =
                    orders.firstWhere((element) => element.id == value);
                order.orderStatus = 'Dispatched';
                setState(() {
                  orders.removeWhere((element) => element.id == value);
                });
                await widget.orderRepository.save(order, getOrderFromJson);
              }
              break;
          }
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

    setState(() {
      isLoading = true;
    });

    final result =
        await deserializeFauna<Order>(query, client, getOrderFromJson);

    setState(() {
      orders = result;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // add spinner if length is 0
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
              child: CheckboxListTile(
            contentPadding: const EdgeInsets.all(10),
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(order.companyName),
            ),
            subtitle: Text(
                "Order Date: ${order.createdAt}\nOrder Deadline: ${formatDate()}\n\n${order.orderDetails}"),
            value: widget.orders.containsKey(order.id),
            onChanged: (bool? value) {
              if (value == true) {
                setState(() {
                  widget.orders[order.id] = order;
                });
              } else {
                setState(() {
                  widget.orders.remove(order.id);
                });
              }
            },
          ));
        });
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:order_management/utils.dart';

import 'constants.dart';
import 'models/order.dart';

import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';

class Dispatched extends StatefulWidget {
  const Dispatched(
      {Key? key, required this.orderRepository,required this.orders, required this.orderStream})
      : super(key: key);

  final StreamController<Map<EventType, dynamic>> orderStream;
  final Map<String,Order> orders;
  final OrderRepository orderRepository;

  @override
  _DispatchedState createState() => _DispatchedState();
}

class _DispatchedState extends State<Dispatched> {
  final client = FaunaClient(FaunaConfig.build(secret: faunaKey));

  StreamSubscription<Map<EventType, dynamic>>? streamSubscription;

  bool isLoading = false;

  List<Order> orders = [];

  Future<void> handleEvent(Map<EventType, dynamic> event) async {
    final key = event.keys.first;
    final value = event.values.first;
    switch (key) {
      case EventType.orderDeleted:
        if (value is Map<String, Order>) {
          setState(() {
            orders.removeWhere((element) {
              if (value.containsKey(element.id)) {
                widget.orderRepository.remove(element.id, getOrderFromJson);
                return true;
              }
              return false;
            });
          });
        }
        break;
      case EventType.search:
        {
          if (value is String && value.isNotEmpty) {
            final query = Map_(
                Paginate(Match(Index('orders_by_company'),
                    terms: [value, 'Dispatched'])),
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
          } else {
            loadOrders();
          }
        }
        break;
    }
  }

  @override
  void initState() {
    if (mounted) {
      setState(() {
        streamSubscription = widget.orderStream.stream.listen((event) {
          handleEvent(event);
        });
      });
    }

    loadOrders();
    super.initState();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    client.close();
    super.dispose();
  }

  void loadOrders() async {
    // final query = Map_(
    //     Paginate(Match(Index('dispatched_orders'), terms: ["Dispatched"])),
    //     Lambda("order", Get(Var("order"))));

    setState(() {
      isLoading = true;
    });

    final query = Call(Function_('get_filtered_orders'),arguments: ['Dispatched']);

    final result =
        await deserializeFauna<Order>(query, client, getOrderFromJson);

    setState(() {
      orders = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final createdAt = DateTime.parse(order.createdAt);
        final deadline = DateTime.parse(order.deadline);
        return Card(
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.all(10),
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(order.companyName),
              ),
              subtitle: Text(
                  "Order Date: ${formatDate(createdAt)}\nOrder Deadline: ${formatDate(deadline)}\n\n${order.orderDetails}"),
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
      },
    );
  }
}

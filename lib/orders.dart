import 'dart:async';

import 'package:faunadb_data/faunadb_data.dart';
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
      required this.user, required this.openModal,
      required this.orderRepository})
      : super(key: key);

  final StreamController<Map<EventType, dynamic>> orderStream;
  final User? user;
  final Function openModal;
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

  Future<void> handleEvent(Map<EventType, dynamic> event) async {
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
                widget.orderRepository.remove(element.id, getOrderFromJson);
                return true;
              }
              return false;
            });
          });
        }
        break;
      case EventType.orderDispatched:
        if (value is Map<String, Order>) {
          setState(() {
            orders.removeWhere((element) {
              final order = element;
              order.orderStatus = 'Dispatched';
              if (value.containsKey(element.id)) {
                widget.orderRepository.save(order, getOrderFromJson);
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
            // final query = Map_(
            //     Paginate(
            //         Match(Index('orders_by_company'), terms: [value,'Pending'])),
            //     Lambda("order", Get(Var("order"))));

            final query = Call(Function_("search_orders"),
                arguments: [value, 'Pending', false]);

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

  void loadOrders() async {
    // final query = Map_(
    //     Paginate(Match(Index('dispatched_orders'), terms: ["Pending"])),
    //     Lambda("order", Get(Var("order"))));

    final query =
        Call(Function_('get_filtered_orders'), arguments: ['Pending']);

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
          final createdAt = DateTime.parse(order.createdAt);
          final deadline = DateTime.parse(order.deadline);
          return Card(
              child: CheckboxListTile(
            secondary: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                widget.openModal(order);
              },
            ),
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
        });
  }
}

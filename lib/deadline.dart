// generate a stateful widget deadline

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';
import 'package:order_management/utils.dart';

import 'constants.dart';
import 'models/order.dart';

class Deadline extends StatefulWidget {
  const Deadline(
      {Key? key,
      required this.orderStream,
      required this.orders,
      required this.openModal,
      required this.orderRepository})
      : super(key: key);

  final StreamController<Map<EventType, dynamic>> orderStream;
  final Map<String, Order> orders;
  final Function openModal;
  final OrderRepository orderRepository;

  @override
  _DeadlineState createState() => _DeadlineState();
}

class _DeadlineState extends State<Deadline> {
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
            // final query = Map_(
            //     Paginate(Match(Index('orders_by_company'),
            //         terms: [value, 'Pending'])),
            //     Lambda("order", Get(Var("order"))));

            final query = Call(Function_("search_orders"),
                arguments: [value, 'Pending', true]);

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

    final query =
        Call(Function_('get_deadlined_orders'), arguments: ['Pending']);

    final result =
        await deserializeFauna<Order>(query, client, getOrderFromJson);

    setState(() {
      orders = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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
          secondary: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              widget.openModal(order);
            },
          ),
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

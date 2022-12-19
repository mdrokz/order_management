// generate a stateful widget user

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';

import 'package:order_management/utils.dart';

import 'constants.dart';

import 'models/user.dart';

class Users extends StatefulWidget {
  const Users(
      {Key? key,
      required this.userStream,
      required this.users,
      required this.userRepository})
      : super(key: key);

  final StreamController<Map<EventType, dynamic>> userStream;
  final Map<String, User> users;
  final UserRepository userRepository;

  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<Users> {
  final client = FaunaClient(FaunaConfig.build(secret: faunaKey));

  StreamSubscription<Map<EventType, dynamic>>? streamSubscription;

  bool isLoading = false;

  List<User> users = [];

  Future<void> handleEvent(Map<EventType, dynamic> event) async {
    final key = event.keys.first;
    final value = event.values.first;
    switch (key) {
      case EventType.userAdded:
        if (value is User) {
          setState(() {
            users.add(value);
          });
        }
        break;

      case EventType.search:
        {
          if (value is String && value.isNotEmpty) {
          } else {
            loadUsers();
          }
          break;
        }

      case EventType.userDeleted:
        if (value is Map<String, User>) {
          setState(() {
            users.removeWhere((element) {
              if (value.containsKey(element.id)) {
                widget.userRepository.remove(element.id, getUserFromJson);
                return true;
              }
              return false;
            });
          });
        }

        break;
      default:
    }
  }

  void loadUsers() async {
    final query = Map_(
        Paginate(Match(Index('users_by_type'), terms: ["factory"])),
        Lambda("user", Get(Var("user"))));

    setState(() {
      isLoading = true;
    });

    final result = await deserializeFauna<User>(query, client, getUserFromJson);

    setState(() {
      users = result;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    streamSubscription = widget.userStream.stream.listen(handleEvent);
    loadUsers();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final createdAt = DateTime.parse(user.createdAt);
        return Card(
            child: CheckboxListTile(
          contentPadding: const EdgeInsets.all(10),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(user.name),
          ),
          subtitle: Text(formatDate(createdAt)),
          value: widget.users.containsKey(user.id),
          onChanged: (bool? value) {
            if (value == true) {
              setState(() {
                widget.users[user.id] = user;
              });
            } else {
              setState(() {
                widget.users.remove(user.id);
              });
            }
          },
        ));
      },
    );
  }
}

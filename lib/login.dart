// generate a complete login widget
import 'package:flutter/material.dart';
import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';
import 'package:localstorage/localstorage.dart';
import 'package:order_management/models/user.dart';
import 'package:order_management/utils.dart';

import 'constants.dart';

class Login extends StatefulWidget {
  const Login({
    Key? key,
  }) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final client = FaunaClient(FaunaConfig.build(secret: faunaKey));

  final localStorage = LocalStorage(localStorageKey);

  final userRepository = UserRepository();

  final _formKey = GlobalKey<FormState>();
  // final _emailController = TextEditingController();
  UserType userType = UserType.shop;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    checkUser();
    super.initState();
  }

  void checkUser() async {
    await localStorage.ready;
    final user = localStorage.getItem('user');
    if(!mounted) return;
    if (user != null) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Form(
                key: _formKey,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: TextFormField(
                      //     controller: _emailController,
                      //     decoration: const InputDecoration(
                      //       border: OutlineInputBorder(),
                      //       labelText: 'Email',
                      //     ),
                      //     validator: (value) {
                      //       if (value == null || value.isEmpty) {
                      //         return 'Please enter some text';
                      //       }
                      //       return null;
                      //     },
                      //   ),
                      // ),
                      // dropdown to select user type
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'User Type',
                          ),
                          items: UserType.values.map((UserType userType) {
                            // final value = userType.toString()
                            return DropdownMenuItem<UserType>(
                              value: userType,
                              child: Text(userType
                                  .toString()
                                  .split('.')[1]
                                  .toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (UserType? value) {
                            setState(() {
                              if (value != null) {
                                userType = value;
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a user type';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Password',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // show snackbar message logging in
                                final scaffoldController =
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Logging in...')));

                                final query = Map_(
                                    Paginate(Match(Index('users_by_type'),
                                        terms: [
                                          (userType.toString().split('.')[1])
                                        ])),
                                    Lambda("user", Get(Var("user"))));

                                final users = await deserializeFauna<User>(
                                    query, client, getUserFromJson);

                                for (final user in users) {
                                  final split = user.password.split(":");

                                  final salt = split[0];

                                  final hash = split[1];

                                  if (compareHash(
                                      _passwordController.text,
                                      createUint8ListFromHexString(salt),
                                      hash)) {
                                    await localStorage.setItem(
                                        'user', user.model());
                                    if (!mounted) {
                                      return;
                                    }
                                    scaffoldController.close();
                                    Navigator.pop(context);
                                    return;
                                  } else {
                                    if(!mounted) return;
                                    scaffoldController.close();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Incorrect password or user type')));
                                  }
                                }
                              }
                            },
                            child: const Text("Login"),
                          ))
                    ]))));
  }
}

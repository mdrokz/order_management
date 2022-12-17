import 'dart:math';
import 'dart:typed_data';

import 'package:faunadb_data/faunadb_data.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';
import 'package:order_management/models/user.dart';
import 'package:pointycastle/export.dart';


enum EventType {
  orderAdded,
  orderDispatched,
  orderDeleted,
}

String formatDate() {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('MMMM d, y').format(now);
  return formattedDate;
}

Future<void> createUser(UserRepository userRepository,UserType userType, String password) async {
  final id = await userRepository.nextId();
  if (id.isPresent) {
    final user = User(id.value, userType,
        password, formatDate());
    try {
      final result = await userRepository.save(
          user, getUserFromJson);
      // await localStorage.setItem('user', result.model());
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
  }
}

Future<List<T>> deserializeFauna<T>(Expr query,FaunaClient client,Function deserialize) async {
  final result = await client.query(query);

  final data = result.toJson();
  final resource = data['resource'];
  var listResult = List<T>.empty(growable: true);
  if (resource != null) {
    List dataObjects = resource['data'];
    for (var item in dataObjects) {
      T t = deserialize(item.object["data"]);
      listResult.add(t);
    }
  }

  return listResult;
}

String hashPassword(String password) {
  final salt = Uint8List.fromList(List.generate(16, (index) => Random.secure().nextInt(256)));

  final params = Argon2Parameters(
    Argon2Parameters.ARGON2_i,
    salt,
    desiredKeyLength: 16,
    iterations: 3,
    memory: 32,
  );

  final keyDerivator = Argon2BytesGenerator();

  keyDerivator.init(params);

  final passwordBytes = Uint8List.fromList(password.codeUnits);

  final key = keyDerivator.process(passwordBytes);

  // convert result to hex
  final hex = key.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  final saltHex = salt.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  return "$saltHex:$hex";
}

Uint8List createUint8ListFromHexString(String hex) {
  var result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    var num = hex.substring(i, i + 2);
    var byte = int.parse(num, radix: 16);
    result[i ~/ 2] = byte;
  }
  return result;
}

// compare hash without salt using argon2
bool compareHash(String password,Uint8List salt, String hash) {

  final params = Argon2Parameters(
    Argon2Parameters.ARGON2_i,
    salt,
    desiredKeyLength: 16,
    iterations: 3,
    memory: 32,
  );

  final keyDerivator = Argon2BytesGenerator();

  keyDerivator.init(params);

  final passwordBytes = Uint8List.fromList(password.codeUnits);

  final key = keyDerivator.process(passwordBytes);

  final hex = key.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  return hex == hash;
}
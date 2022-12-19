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

final keyDerivator = Argon2BytesGenerator();

enum EventType {
  orderAdded,
  search,
  orderDispatched,
  orderDeleted,
  userAdded,
  userDeleted,
}

String formatDate(DateTime dateTime) {
  String formattedDate = DateFormat('MMMM d, y').format(dateTime);
  return formattedDate;
}

Future<User?> createUser(UserRepository userRepository, UserType userType,
    String name, String password) async {
  final id = await userRepository.nextId();
  if (id.isPresent) {
    final user = User(
        id.value, userType, name, hashPassword(password), DateTime.now().toIso8601String());

    try {
      final result = await userRepository.save(user, getUserFromJson);

      return result;
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

    return null;
  }
  return null;
}

// implement function to compare if date1 is greater than date2 using Intl
bool compareDate(String date1, String date2) {
  final date1Formatted = DateFormat('MMMM d, y').parse(date1);
  final date2Formatted = DateFormat('MMMM d, y').parse(date2);
  return date1Formatted.isAfter(date2Formatted);
}

Future<List<T>> deserializeFauna<T>(
    Expr query, FaunaClient client, Function deserialize) async {
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
  final salt = Uint8List.fromList(
      List.generate(16, (index) => Random.secure().nextInt(256)));

  final params = Argon2Parameters(
    Argon2Parameters.ARGON2_id,
    salt,
    desiredKeyLength: 16,
    iterations: 3,
    memory: 32,
  );

  // final keyGenerator = Argon2BytesGenerator();

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
bool compareHash(String password, String hash) {
  final hashParts = hash.split(':');
  final salt = createUint8ListFromHexString(hashParts[0]);
  final hashBytes = createUint8ListFromHexString(hashParts[1]);

  final params = Argon2Parameters(
    Argon2Parameters.ARGON2_id,
    salt,
    desiredKeyLength: 16,
    iterations: 3,
    memory: 32,
  );

  keyDerivator.init(params);

  final passwordBytes = Uint8List.fromList(password.codeUnits);

  final key = keyDerivator.process(passwordBytes);

  // final hex = key.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  return constantTimeEqual(key, hashBytes);
}

bool constantTimeEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;

  int result = 0;
  for (int i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}
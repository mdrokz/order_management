import 'package:faunadb_data/faunadb_data.dart';

enum UserType { factory, shop }

// map string to enum
UserType userTypeFromString(String userType) {
  return UserType.values.firstWhere((e) => e.toString().split(".")[1] == userType);
}

extension UserTypeExtension on UserType {
  // map enum to string
  String get value => {
        UserType.factory: 'factory',
        UserType.shop: 'shop',
      }[this]!;
}

class User extends Entity<User> {
  String id;
  UserType userType;
  String name;
  String password;
  String createdAt;

  User(this.id, this.userType,this.name, this.password,
      this.createdAt);

  @override
  fromJson(Map<String, dynamic> model) {
    return User(
      model['id'],
      userTypeFromString(model['userType']),
      model['name'],
      model['password'],
      model['createdAt'],
    );
  }

  @override
  String getId() {
    return id;
  }

  @override
  Map<String, dynamic> model() {
    return {
      'id': id,
      'userType': userType.value,
      'name': name,
      'password': password,
      'createdAt': createdAt
    };
  }

  static String collections() => 'Users';
  static String allUsers() => 'all_users';
}

User getUserFromJson(Map<String, dynamic> json) {
  return User(
    json['id'] as String,
    userTypeFromString(json['userType'] as String),
    json['name'] as String,
    json['password'] as String,
    json['createdAt'] as String,
  );
}

class UserRepository extends FaunaRepository<User> {
  UserRepository() : super(User.collections(), User.allUsers());
}
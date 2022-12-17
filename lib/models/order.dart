import 'package:faunadb_data/faunadb_data.dart';

class Order extends Entity<Order> {
  String id;
  String companyName;
  String orderDetails;
  String orderStatus;
  String deadline;
  String createdAt;

  Order(this.id, this.companyName, this.orderDetails, this.orderStatus,
      this.deadline,this.createdAt);

  @override
  fromJson(Map<String, dynamic> model) {
    return Order(
      model['id'],
      model['companyName'],
      model['orderDetails'],
      model['orderStatus'],
      model['deadline'],
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
      'companyName': companyName,
      'orderDetails': orderDetails,
      'orderStatus': orderStatus,
      'deadline': deadline,
      'createdAt': createdAt
    };
  }

  static String collections() => 'Orders';
  static String allOrders() => 'all_orders';
}

Order getOrderFromJson(Map<String, dynamic> json) {
  return Order(
    json['id'] as String,
    json['companyName'] as String,
    json['orderDetails'] as String,
    json['orderStatus'] as String,
    json['deadline'] as String,
    json['createdAt'] as String,
  );
}

class OrderRepository extends FaunaRepository<Order> {
  OrderRepository() : super(Order.collections(), Order.allOrders());
}

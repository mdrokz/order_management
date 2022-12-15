import 'package:intl/intl.dart';
import 'package:faunadb_http/faunadb_http.dart';
import 'package:faunadb_http/query.dart';

String formatDate() {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('MMMM d, y').format(now);
  return formattedDate;
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
/// Represents a response from a database query.
///
/// [data] contains the response data from the query, which can be a list of
/// maps, a single map, or `null` if the query did not return any data.
///
/// [insertId] is the ID of the last inserted row, if the query was an insert
/// operation.
///
/// [affectedRows] is the number of rows affected by the query, if the query
/// was an update or delete operation.
class DatabaseResponse {
  final dynamic data;
  final int? insertId;
  final int? affectedRows;

  DatabaseResponse({this.data, this.insertId, this.affectedRows});
}

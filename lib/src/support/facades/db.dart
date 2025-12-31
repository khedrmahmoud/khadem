
import '../../application/khadem.dart';
import '../../contracts/database/database_connection.dart';
import '../../contracts/database/query_builder_interface.dart';
import '../../contracts/database/schema_builder.dart';
import '../../core/database/database.dart';
/// Facade for the database system.
///
/// Provides quick access to database connections, query builders and
/// transaction helpers via static methods, e.g. `DB.table('users')`.
class DB {
  /// Gets the database manager instance.
  static DatabaseManager get _manager => Khadem.make<DatabaseManager>();

  /// Gets the current connection.
  static DatabaseConnection connection([String? name]) {
    return _manager.connection(name);
  }

  /// Begins a new query against a table.
  static QueryBuilderInterface<dynamic> table(String table) {
    return _manager.table(table);
  }

  /// Executes a raw SQL query.
  static Future<dynamic> select(
    String query, [
    List<dynamic> bindings = const [],
  ]) {
    return connection().execute(query, bindings);
  }

  /// Executes an insert statement.
  static Future<dynamic> insert(
    String query, [
    List<dynamic> bindings = const [],
  ]) {
    return connection().execute(query, bindings);
  }

  /// Executes an update statement.
  static Future<dynamic> update(
    String query, [
    List<dynamic> bindings = const [],
  ]) {
    return connection().execute(query, bindings);
  }

  /// Executes a delete statement.
  static Future<dynamic> delete(
    String query, [
    List<dynamic> bindings = const [],
  ]) {
    return connection().execute(query, bindings);
  }

  /// Executes a general statement.
  static Future<dynamic> statement(
    String query, [
    List<dynamic> bindings = const [],
  ]) {
    return connection().execute(query, bindings);
  }

  /// Runs a transaction.
  static Future<T> transaction<T>(
    Future<T> Function() callback, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
    Future<void> Function(T result)? onSuccess,
    Future<void> Function(dynamic error)? onFailure,
    Future<void> Function()? onFinally,
    String? isolationLevel,
  }) {
    return connection().transaction(
      callback,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      onSuccess: onSuccess,
      onFailure: onFailure,
      onFinally: onFinally,
      isolationLevel: isolationLevel,
    );
  }

  /// Gets the schema builder.
  static SchemaBuilder get schema => _manager.schemaBuilder;
}

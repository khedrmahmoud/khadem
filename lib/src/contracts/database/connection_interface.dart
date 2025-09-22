import 'database_response.dart';
import 'query_builder_interface.dart';

/// Abstract interface for managing a database connection.
///
/// Defines the required methods to interact with the database,
/// such as executing raw SQL, creating query builders, and handling transactions.
abstract class ConnectionInterface {
  /// Establishes a connection to the database.
  Future<void> connect();

  /// Terminates the current database connection.
  Future<void> disconnect();

  /// Executes a raw SQL query with optional parameter bindings.
  ///
  /// Example:
  /// ```dart
  /// await connection.execute('SELECT * FROM users WHERE id = ?', [1]);
  /// ```
  Future<DatabaseResponse> execute(
    String sql, [
    List<dynamic> bindings = const [],
  ]);

  /// Checks if the connection is currently active and usable.
  bool get isConnected;

  /// Returns a query builder for the specified [table].
  ///
  /// You can optionally pass a [modelFactory] for transforming raw results into objects.
  ///
  /// Example:
  /// ```dart
  /// final users = await connection.queryBuilder<User>('users', modelFactory: (row) => User.fromMap(row)).get();
  /// ```
  QueryBuilderInterface<T> queryBuilder<T>(
    String table, {
    T Function(Map<String, dynamic>)? modelFactory,
  });

  /// Executes a transactional block with retry, success/failure hooks.
  ///
  /// - [callback] is the block of code to run inside a transaction.
  /// - [maxRetries] sets the number of retries if transaction fails.
  /// - [retryDelay] sets the delay between retries.
  ///
  /// Hooks:
  /// - [onSuccess] called when the transaction commits successfully.
  /// - [onFailure] called if the transaction throws an error.
  /// - [onFinally] always called after transaction completes.
  Future<T> transaction<T>(
    Future<T> Function() callback, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
    Future<void> Function(T result)? onSuccess,
    Future<void> Function(dynamic error)? onFailure,
    Future<void> Function()? onFinally,
  });

  /// Sends a ping or heartbeat to check if connection is alive.
  Future<bool> ping();
}


import 'package:mysql1/mysql1.dart';
import '../../../contracts/database/connection_interface.dart';
import '../../../contracts/database/database_response.dart';
import '../../../contracts/database/query_builder_interface.dart';
import '../../exceptions/database_exception.dart';
import 'mysql_query_builder.dart';

/// Concrete implementation of [ConnectionInterface] for MySQL using `mysql1` package.
class MySQLConnection implements ConnectionInterface {
  final Map<String, dynamic> _config;
  MySqlConnection? _connection;

  MySQLConnection(this._config);

  @override
  Future<void> connect() async {
    final settings = ConnectionSettings(
      host: _config['host'] ?? 'localhost',
      port: _config['port'] ?? 3306,
      user: _config['username'] ?? 'root',
      password: _config['password'],

      // db: _config['database'],
    );
    _connection = await MySqlConnection.connect(settings);
    await _ensureDatabaseExists(_config['database']);
  }

  Future<void> _ensureDatabaseExists(String dbName) async {
    try {
      await execute('USE $dbName');
    } catch (_) {

      //throw DatabaseException('❌ Database "$dbName" must exist to connect.');

    }
  }

  @override
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  @override
  bool get isConnected => _connection != null;

  @override
  Future<DatabaseResponse> execute(String sql,
      [List<dynamic> bindings = const [],]) async {
    if (_connection == null) {
      throw DatabaseException('MySQL connection is not established');
    }

    final results = await _connection!.query(sql, bindings);

    return DatabaseResponse(
        insertId: results.insertId,
        affectedRows: results.affectedRows,
        data: results.map((row) => row.fields).toList(),);
  }

  @override
  QueryBuilderInterface<T> queryBuilder<T>(String table,
      {T Function(Map<String, dynamic>)? modelFactory,}) {
    return MySQLQueryBuilder<T>(this, table, modelFactory: modelFactory);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function() callback, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
    Future<void> Function(T result)? onSuccess,
    Future<void> Function(dynamic error)? onFailure,
    Future<void> Function()? onFinally,
  }) async {
    if (!isConnected) {
      throw DatabaseException('MySQL connection is not established');
    }

    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        await execute('START TRANSACTION');
        final result = await callback();
        await execute('COMMIT');

        if (onSuccess != null) {
          await onSuccess(result);
        }

        return result;
      } catch (e) {
        await execute('ROLLBACK');

        attempt++;
        if (attempt >= maxRetries) {
          if (onFailure != null) await onFailure(e);
          throw DatabaseException(
              'Transaction failed after $maxRetries retries: $e',);
        }

        await Future.delayed(retryDelay * attempt);
      } finally {
        if (onFinally != null) await onFinally();
      }
    }

    throw DatabaseException('Transaction could not be completed');
  }

  /// Performs a ping to check if the database connection is alive.
  @override
  Future<bool> ping() async {
    try {
      final result = await execute('SELECT 1');
      return result.data.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

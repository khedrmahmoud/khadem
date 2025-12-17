import 'package:khadem/khadem.dart';
import 'package:mysql1/mysql1.dart';

/// Concrete implementation of [DatabaseConnection] for MySQL using `mysql1` package.
class MySQLConnection implements DatabaseConnection {
  final Map<String, dynamic> _config;
  MySqlConnection? _connection;

  MySQLConnection(this._config);

  // ===========================================================================
  // Connection Management
  // ===========================================================================

  @override
  bool get isConnected => _connection != null;

  @override
  Future<void> connect() async {
    final settings = ConnectionSettings(
      host: _config['host'] ?? 'localhost',
      port: _config['port'] ?? 3306,
      user: _config['username'] ?? 'root',
      password: _config['password']?.toString().isEmpty == true
          ? null
          : _config['password'],
      useSSL: _config['ssl'] ?? false,
      timeout: _config['timeout'] != null
          ? Duration(milliseconds: _config['timeout'])
          : const Duration(seconds: 30),
    );

    _connection = await MySqlConnection.connect(settings);
    await _ensureDatabaseSelected(_config['database']);
  }

  @override
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
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

  Future<void> _ensureDatabaseSelected(String? dbName) async {
    if (dbName == null || dbName.isEmpty) return;

    try {
      await execute('USE `$dbName`');
    } catch (_) {
      // If USE fails, try to create it
      try {
        Khadem.logger.info('Database $dbName does not exist. Creating...');
        await execute(
          'CREATE DATABASE IF NOT EXISTS `$dbName` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci',
        );
        await execute('USE `$dbName`');
        Khadem.logger.info('Database $dbName created and selected.');
      } catch (e) {
        Khadem.logger.info(
          'ERROR: Failed to create or select database $dbName: $e',
        );
        rethrow;
      }
    }
  }

  // ===========================================================================
  // Query Execution
  // ===========================================================================

  @override
  Future<DatabaseResponse> execute(
    String sql, [
    List<dynamic> bindings = const [],
  ]) async {
    if (_connection == null) {
      await connect();
    }

    try {
      return await _executeInternal(sql, bindings);
    } catch (e) {
      // Check if it's a connection error and retry once
      if (_isConnectionError(e)) {
        Khadem.logger.warning('Database connection lost. Reconnecting...');
        try {
          await disconnect();
          await connect();
          return await _executeInternal(sql, bindings);
        } catch (reconnectError) {
          throw DatabaseException(
            'Failed to reconnect and execute query: $reconnectError',
            details: e,
            sql: sql,
            bindings: bindings,
          );
        }
      }

      Khadem.logger.info('SQL Error: $e\nQuery: $sql\nBindings: $bindings');
      throw DatabaseException(
        'SQL Execution Error: $e',
        details: e,
        sql: sql,
        bindings: bindings,
      );
    }
  }

  Future<DatabaseResponse> _executeInternal(
      String sql, List<dynamic> bindings,) async {
    final results = await _connection!.query(sql, bindings);

    return DatabaseResponse(
      insertId: results.insertId,
      affectedRows: results.affectedRows,
      data: results.map((row) => row.fields).toList(),
    );
  }

  bool _isConnectionError(dynamic e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('closed') ||
        msg.contains('broken pipe') ||
        msg.contains('connection') ||
        msg.contains('server has gone away');
  }

  @override
  QueryBuilderInterface<T> queryBuilder<T>(
    String table, {
    T Function(Map<String, dynamic>)? modelFactory,
  }) {
    return QueryBuilder<T>(
      this,
      MySQLGrammar(),
      table,
      modelFactory: modelFactory,
    );
  }

  @override
  SchemaBuilder getSchemaBuilder() {
    return MySQLSchemaBuilder();
  }

  // ===========================================================================
  // Transactions
  // ===========================================================================

  @override
  Future<void> beginTransaction() async {
    await execute('START TRANSACTION');
  }

  @override
  Future<void> commit() async {
    await execute('COMMIT');
  }

  @override
  Future<void> rollBack() async {
    await execute('ROLLBACK');
  }

  @override
  Future<void> unprepared(String sql) async {
    await execute(sql);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function() callback, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
    Future<void> Function(T result)? onSuccess,
    Future<void> Function(dynamic error)? onFailure,
    Future<void> Function()? onFinally,
    String? isolationLevel,
  }) async {
    if (!isConnected) {
      await connect();
    }

    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        if (isolationLevel != null) {
          await execute('SET TRANSACTION ISOLATION LEVEL $isolationLevel');
        }
        await execute('START TRANSACTION');
        final result = await callback();
        await execute('COMMIT');

        if (onSuccess != null) {
          await onSuccess(result);
        }

        return result;
      } catch (e) {
        try {
          await execute('ROLLBACK');
        } catch (_) {
          // Ignore rollback errors if connection is lost
        }

        attempt++;
        if (attempt >= maxRetries) {
          if (onFailure != null) await onFailure(e);
          throw DatabaseException(
            'Transaction failed after $maxRetries retries: $e',
            details: e,
          );
        }

        await Future.delayed(retryDelay * attempt);
      } finally {
        if (onFinally != null) await onFinally();
      }
    }

    throw DatabaseException('Transaction could not be completed');
  }
}

import 'package:khadem/contracts.dart'
    show
        DatabaseConnection,
        DatabaseResponse,
        QueryBuilderInterface,
        SchemaBuilder;
import 'package:khadem/support.dart' show Log, DatabaseException;
import 'package:mysql1/mysql1.dart';

import '../../query/grammars/mysql_grammar.dart';
import '../../query/query_builder.dart';
import 'mysql_schema_builder.dart';

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

    // Validate database name to prevent SQL injection
    // Database names must be alphanumeric with underscores only
    _validateDatabaseName(dbName);

    // Use the validated name with backtick quoting
    // Note: We already validated the name doesn't contain backticks
    try {
      await execute('USE `$dbName`');
    } catch (_) {
      // If USE fails, try to create it
      try {
        Log.info('Database $dbName does not exist. Creating...');
        await execute(
          'CREATE DATABASE IF NOT EXISTS `$dbName` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci',
        );
        await execute('USE `$dbName`');
        Log.info('Database $dbName created and selected.');
      } catch (e) {
        Log.info('ERROR: Failed to create or select database $dbName: $e');
        rethrow;
      }
    }
  }

  /// Validates database name to prevent SQL injection.
  ///
  /// MySQL identifiers can contain alphanumeric characters,
  /// underscores, and dollar signs. They cannot start with a digit.
  ///
  /// Throws [DatabaseException] if the name is invalid.
  void _validateDatabaseName(String dbName) {
    // Check for empty or too long (MySQL limit is 64 characters)
    if (dbName.isEmpty || dbName.length > 64) {
      throw DatabaseException('Invalid database name: must be 1-64 characters');
    }

    // Check for valid characters: alphanumeric, underscore, dollar sign
    // Must not start with a digit
    final validPattern = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');
    if (!validPattern.hasMatch(dbName)) {
      throw DatabaseException(
        'Invalid database name: must contain only alphanumeric characters, underscores, and dollar signs, and cannot start with a digit',
      );
    }

    // Explicitly check for backticks which could break out of quoting
    if (dbName.contains('`')) {
      throw DatabaseException(
        'Invalid database name: cannot contain backtick characters',
      );
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
        Log.warning('Database connection lost. Reconnecting...');
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

      Log.info('SQL Error: $e\nQuery: $sql\nBindings: $bindings');
      throw DatabaseException(
        'SQL Execution Error: $e',
        details: e,
        sql: sql,
        bindings: bindings,
      );
    }
  }

  Future<DatabaseResponse> _executeInternal(
    String sql,
    List<dynamic> bindings,
  ) async {
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
    Duration retryDelay = const Duration(milliseconds: 100),
    Future<void> Function(T result)? onSuccess,
    Future<void> Function(dynamic error)? onFailure,
    Future<void> Function()? onFinally,
    String? isolationLevel,
  }) async {
    if (!isConnected) {
      await connect();
    }

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

      if (onFailure != null) await onFailure(e);
      rethrow;
    } finally {
      if (onFinally != null) await onFinally();
    }
  }
}

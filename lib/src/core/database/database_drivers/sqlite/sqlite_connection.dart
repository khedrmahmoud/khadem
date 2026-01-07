import 'dart:async';

import 'package:sqlite3/sqlite3.dart';

import '../../../../contracts/database/database_connection.dart';
import '../../../../contracts/database/database_response.dart';
import '../../../../contracts/database/query_builder_interface.dart';
import '../../../../contracts/database/schema_builder.dart';
import '../../../../support/exceptions/database_exception.dart';
import '../../query/grammars/sqlite_grammar.dart';
import '../../query/query_builder.dart';
import 'sqlite_schema_builder.dart';

/// Concrete implementation of [DatabaseConnection] for SQLite using `sqlite3` package.
class SQLiteConnection implements DatabaseConnection {
  final String _path;
  Database? _db;

  SQLiteConnection(Map<String, dynamic> config)
      : _path = config['database'] ?? 'khadem.db';

  // ===========================================================================
  // Connection Management
  // ===========================================================================

  @override
  bool get isConnected => _db != null;

  @override
  Future<void> connect() async {
    try {
      _db = sqlite3.open(_path);
    } catch (e) {
      throw DatabaseException('Failed to open SQLite database at $_path: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _db?.dispose();
    _db = null;
  }

  @override
  Future<bool> ping() async {
    try {
      if (_db == null) return false;
      _db!.select('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // Execution
  // ===========================================================================

  @override
  Future<DatabaseResponse> execute(
    String sql, [
    List<dynamic> bindings = const [],
  ]) async {
    if (_db == null) await connect();

    final preparedBindings = _prepareBindings(bindings);

    try {
      final stmt = _db!.prepare(sql);

      // Simple heuristic: check if it starts with SELECT (case insensitive)
      final isSelect = sql.trim().toUpperCase().startsWith('SELECT') ||
          sql.trim().toUpperCase().startsWith('PRAGMA');

      if (isSelect) {
        final result = stmt.select(preparedBindings);
        stmt.dispose();

        final data =
            result.map((row) => Map<String, dynamic>.from(row)).toList();
        return DatabaseResponse(data: data);
      } else {
        stmt.execute(preparedBindings);
        stmt.dispose();

        return DatabaseResponse(
          data: [],
          insertId: _db!.lastInsertRowId,
          affectedRows: _db!.updatedRows,
        );
      }
    } catch (e) {
      throw DatabaseException(
        'SQLite Error: $e\nQuery: $sql\nBindings: $preparedBindings',
      );
    }
  }

  List<dynamic> _prepareBindings(List<dynamic> bindings) {
    return bindings.map((value) {
      if (value is DateTime) {
        return value.toIso8601String();
      }
      return value;
    }).toList();
  }

  @override
  Future<void> unprepared(String sql) async {
    if (_db == null) await connect();
    try {
      _db!.execute(sql);
    } catch (e) {
      throw DatabaseException('SQLite Unprepared Error: $e\nQuery: $sql');
    }
  }

  // ===========================================================================
  // Builders
  // ===========================================================================

  @override
  QueryBuilderInterface<T> queryBuilder<T>(
    String table, {
    T Function(Map<String, dynamic>)? modelFactory,
  }) {
    return QueryBuilder<T>(
      this,
      SQLiteGrammar(),
      table,
      modelFactory: modelFactory,
    );
  }

  @override
  SchemaBuilder getSchemaBuilder() {
    return SQLiteSchemaBuilder();
  }

  // ===========================================================================
  // Transactions
  // ===========================================================================

  @override
  Future<void> beginTransaction() async {
    await unprepared('BEGIN TRANSACTION');
  }

  @override
  Future<void> commit() async {
    await unprepared('COMMIT');
  }

  @override
  Future<void> rollBack() async {
    await unprepared('ROLLBACK');
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
        // SQLite isolation levels are handled differently (DEFERRED, IMMEDIATE, EXCLUSIVE)
        // We can map standard levels or just use BEGIN
        if (isolationLevel != null) {
          // SQLite doesn't support SET TRANSACTION ISOLATION LEVEL standard syntax easily
          // We'll ignore for now or map 'SERIALIZABLE' to 'BEGIN EXCLUSIVE' etc.
        }

        await beginTransaction();
        final result = await callback();
        await commit();

        if (onSuccess != null) {
          await onSuccess(result);
        }

        return result;
      } catch (e) {
        try {
          await rollBack();
        } catch (_) {
          // Ignore rollback errors
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

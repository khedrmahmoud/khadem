import 'dart:async';

import '../../contracts/validation/rule.dart';
import '../facades/db.dart';

/// Validates that a value is unique in a database table.
///
/// Signature: `unique:table,column,except,idColumn,extraCol,extraVal...`
///
/// Examples:
/// - `unique:users,email` - Email must be unique in users table.
/// - `unique:users,email,1` - Email unique, ignoring id 1.
/// - `unique:users,email,1,user_id` - Email unique, ignoring user_id 1.
/// - `unique:users,email,NULL,NULL,role,admin` - Email unique AND role=admin.
class UniqueRule extends Rule {
  final String? _table;
  final String? _column;
  final dynamic _ignoreId;
  final String _ignoreColumn;

  UniqueRule([
    this._table,
    this._column,
    this._ignoreId,
    this._ignoreColumn = 'id',
  ]);

  @override
  String get signature => 'unique';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    final value = context.value;
    final args = context.parameters;
    final field = context.attribute;

    // specific check: if value is null/empty, unique check usually passes (unless required).
    if (value == null || value.toString().trim().isEmpty) {
      return true;
    }

    var tableName = _table;
    var columnName = _column;
    var ignoreIdValue = _ignoreId;
    var ignoreColumnName = _ignoreColumn;
    final extraClauses = <Map<String, dynamic>>[];

    // Parse string arguments if provided
    if (args.isNotEmpty) {
      tableName = args[0];
      if (args.length > 1 && args[1].toUpperCase() != 'NULL') {
        columnName = args[1];
      }
      if (args.length > 2 && args[2].toUpperCase() != 'NULL') {
        ignoreIdValue = args[2];
      }
      if (args.length > 3 && args[3].toUpperCase() != 'NULL') {
        ignoreColumnName = args[3];
      }

      // Extra where clauses: key,value pairs starting from index 4
      for (int i = 4; i < args.length; i += 2) {
        if (i + 1 < args.length) {
          extraClauses.add({
            'column': args[i],
            'value': args[i + 1],
          });
        }
      }
    }

    if (tableName == null) {
      throw Exception("UniqueRule requires a table name.");
    }

    final db = DB.table(tableName);
    final dbColumn = columnName ?? field;

    // Main unique check
    db.where(dbColumn, '=', value);

    // Ignore specific ID (for updates)
    if (ignoreIdValue != null) {
      db.where(ignoreColumnName, '!=', ignoreIdValue);
    }

    // Apply extra clauses
    for (final clause in extraClauses) {
      final col = clause['column'];
      final val = clause['value'];
      if (val == 'NULL') {
        db.whereNull(col);
      } else if (val == 'NOT_NULL') {
        db.whereNotNull(col);
      } else {
        db.where(col, '=', val);
      }
    }

    // If record exists, then it is NOT unique -> fail.
    if (await db.exists()) {
      return false;
    }

    return true;
  }

  @override
  String message(ValidationContext context) => 'unique_validation';
}

/// Validates that a value exists in a database table.
///
/// Signature: `exists:table,column,extraCol,extraVal...`
///
/// Examples:
/// - `exists:states,code` - Value must exist in states table, code column.
/// - `exists:users,email,role,admin` - Value must exist in users table where email=value AND role=admin.
class ExistsRule extends Rule {
  final String? _table;
  final String? _column;

  ExistsRule([this._table, this._column]);

  @override
  String get signature => 'exists';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    final value = context.value;
    final args = context.parameters;
    final field = context.attribute;

    if (value == null || value.toString().trim().isEmpty) {
      return true;
    }

    var tableName = _table;
    var columnName = _column;
    final extraClauses = <Map<String, dynamic>>[];

    if (args.isNotEmpty) {
      tableName = args[0];
      if (args.length > 1 && args[1].toUpperCase() != 'NULL') {
        columnName = args[1];
      }

      // Extra where clauses: key,value pairs starting from index 2
      for (int i = 2; i < args.length; i += 2) {
        if (i + 1 < args.length) {
          extraClauses.add({
            'column': args[i],
            'value': args[i + 1],
          });
        }
      }
    }

    if (tableName == null) {
      throw Exception("ExistsRule requires a table name.");
    }

    final db = DB.table(tableName);
    final dbColumn = columnName ?? field;

    db.where(dbColumn, '=', value);

    // Apply extra clauses
    for (final clause in extraClauses) {
      final col = clause['column'];
      final val = clause['value'];
      if (val == 'NULL') {
        db.whereNull(col);
      } else if (val == 'NOT_NULL') {
        db.whereNotNull(col);
      } else {
        db.where(col, '=', val);
      }
    }

    // If record exists -> pass.
    return await db.exists();
  }

  @override
  String message(ValidationContext context) => 'exists_validation';
}

import '../../../contracts/database/schema_builder.dart';

import '../../../core/database/schema/blueprint.dart';
import '../../../core/database/schema/column_definition.dart';

class MySQLSchemaBuilder implements SchemaBuilder {
  final List<String> _queries = [];

  @override
  void create(String tableName, void Function(Blueprint) callback) {
    final blueprint = Blueprint(tableName);
    callback(blueprint);

    final columnSQLs = blueprint.columns.map(_columnToSQL).toList();
    final constraints = _generateConstraints(blueprint.columns, tableName);
    final fullSQL = [
      ...columnSQLs,
      ...constraints,
    ].join(', ');

    _queries.add('CREATE TABLE `$tableName` ($fullSQL);');
  }

  @override
  void dropIfExists(String tableName) {
    _queries.add('DROP TABLE IF EXISTS `$tableName`;');
  }

  /// Converts a column definition to SQL syntax
  String _columnToSQL(ColumnDefinition column) {
    final parts = <String>[];

    // Column name and type
    if (column.enumValues != null) {
      final enumValues = column.enumValues!.map((e) => "'$e'").join(', ');
      parts.add('`${column.name}` ENUM($enumValues)');
    } else if (column.generatedExpression != null) {
      parts.add(
          '`${column.name}` AS (${column.generatedExpression}) ${column.isStoredGenerated ? 'STORED' : 'VIRTUAL'}',);
    } else {
      parts.add('`${column.name}` ${_getTypeWithLength(column)}');
    }

    // NULL / NOT NULL
    if (!column.isNullable) {
      parts.add('NOT NULL');
    } else {
      parts.add('NULL');
    }

    // AUTO_INCREMENT
    if (column.isAutoIncrement) {
      parts.add('AUTO_INCREMENT');
    }

    // DEFAULT
    if (column.defaultValue != null && column.generatedExpression == null) {
      parts.add("DEFAULT '${column.defaultValue}'");
    }

    // COMMENT
    if (column.comment != null) {
      parts.add("COMMENT '${column.comment}'");
    }

    // PRIMARY / UNIQUE
    if (column.isPrimary) {
      parts.add('PRIMARY KEY');
    } else if (column.isUnique) {
      parts.add('UNIQUE');
    }

    // CHECK
    if (column.checkConstraint != null) {
      parts.add('CHECK (${column.checkConstraint})');
    }

    return parts.join(' ');
  }

  /// Handles indexes and foreign keys separately
  List<String> _generateConstraints(
      List<ColumnDefinition> columns, String tableName,) {
    final constraints = <String>[];

    for (final column in columns) {
      // Index
      if (column.isIndexed && !column.isPrimary && !column.isUnique) {
        constraints.add('INDEX `${column.name}_idx` (`${column.name}`)');
      }

      // Foreign keys
      if (column.foreignTable != null && column.foreignKey != null) {
        final fkName = '${tableName}_${column.name}_fk';
        final onDelete = column.onDeleteAction != null
            ? ' ON DELETE ${column.onDeleteAction!.toUpperCase()}'
            : '';
        final onUpdate = column.onUpdateAction != null
            ? ' ON UPDATE ${column.onUpdateAction!.toUpperCase()}'
            : '';

        constraints.add(
            'CONSTRAINT `$fkName` FOREIGN KEY (`${column.name}`) REFERENCES `${column.foreignTable}`(`${column.foreignKey}`)$onDelete$onUpdate',);
      }
    }

    return constraints;
  }

  String _getTypeWithLength(ColumnDefinition column) {
    switch (column.type.toUpperCase()) {
      case 'VARCHAR':
        return 'VARCHAR(${column.length ?? 255})';
      case 'INT':
      case 'BIGINT':
        return column.isUnsigned
            ? '${column.type.toUpperCase()} UNSIGNED'
            : column.type.toUpperCase();
      default:
        return column.type;
    }
  }

  @override
  List<String> get queries => _queries;

  void clear() {
    _queries.clear();
  }

  @override
  void createIfNotExists(
      String tableName, void Function(Blueprint table) callback,) {
    final blueprint = Blueprint(tableName);
    callback(blueprint);

    final columnSQLs = blueprint.columns.map(_columnToSQL).toList();
    final constraints = _generateConstraints(blueprint.columns, tableName);
    final fullSQL = [
      ...columnSQLs,
      ...constraints,
    ].join(', ');

    _queries.add('CREATE TABLE IF NOT EXISTS `$tableName` ($fullSQL);');
  }

  @override
  void drop(String tableName) {
    _queries.add('DROP TABLE `$tableName`;');
  }
}

import '../../../../contracts/database/schema_builder.dart';

import '../../schema/blueprint.dart';
import '../../schema/column_definition.dart';

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

    // 1. Column Name & Type
    parts.add('`${column.name}`');

    if (column.enumValues != null && column.enumValues!.isNotEmpty) {
      final enumValues = column.enumValues!.map((e) => "'$e'").join(', ');
      parts.add('ENUM($enumValues)');
    } else if (column.generatedExpression != null) {
      parts.add(
          'AS (${column.generatedExpression}) ${column.isStoredGenerated ? 'STORED' : 'VIRTUAL'}',);
    } else {
      parts.add(_getTypeWithLength(column));
    }

    // 2. Nullability
    // In MySQL, columns are nullable by default unless NOT NULL is specified.
    // However, explicit NULL/NOT NULL is better.
    parts.add(column.isNullable ? 'NULL' : 'NOT NULL');

    // 3. Default Value
    if (column.defaultValue != null && column.generatedExpression == null) {
      parts.add(_compileDefault(column));
    }

    // 4. Auto Increment
    if (column.isAutoIncrement) {
      parts.add('AUTO_INCREMENT');
    }

    // 5. Primary Key (Inline)
    // Note: It's often better to define PKs at the table level, especially for composite keys.
    // But for single column PKs, inline is fine.
    if (column.isPrimary) {
      parts.add('PRIMARY KEY');
    } else if (column.isUnique) {
      parts.add('UNIQUE');
    }

    // 6. Comments
    if (column.comment != null) {
      parts.add("COMMENT '${column.comment!.replaceAll("'", "\\'")}'");
    }

    // 7. Check Constraints (MySQL 8.0.16+)
    if (column.checkConstraint != null) {
      parts.add('CHECK (${column.checkConstraint})');
    }

    return parts.join(' ');
  }

  String _compileDefault(ColumnDefinition column) {
    final value = column.defaultValue;
    final type = column.type.toUpperCase();

    if (value == null) return 'DEFAULT NULL';

    if (type == 'BOOLEAN' || type == 'BOOL' || type == 'TINYINT') {
      if (value is bool) return 'DEFAULT ${value ? 1 : 0}';
      return 'DEFAULT $value';
    }

    if ([
      'INT',
      'INTEGER',
      'BIGINT',
      'SMALLINT',
      'MEDIUMINT',
      'FLOAT',
      'DOUBLE',
      'DECIMAL',
    ].contains(type)) {
      return 'DEFAULT $value';
    }

    if (value is String) {
      if (value.toUpperCase() == 'CURRENT_TIMESTAMP') {
        return 'DEFAULT CURRENT_TIMESTAMP';
      }
      if (value.toUpperCase() == 'NULL') return 'DEFAULT NULL';
      return "DEFAULT '$value'";
    }

    return "DEFAULT '$value'";
  }

  /// Handles indexes and foreign keys separately
  List<String> _generateConstraints(
    List<ColumnDefinition> columns,
    String tableName,
  ) {
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
          'CONSTRAINT `$fkName` FOREIGN KEY (`${column.name}`) REFERENCES `${column.foreignTable}`(`${column.foreignKey}`)$onDelete$onUpdate',
        );
      }
    }

    return constraints;
  }

  String _getTypeWithLength(ColumnDefinition column) {
    switch (column.type.toUpperCase()) {
      case 'VARCHAR':
        return 'VARCHAR(${column.length ?? 255})';
      case 'CHAR':
        return 'CHAR(${column.length ?? 255})';
      case 'INT':
      case 'INTEGER':
        return column.isUnsigned ? 'INT UNSIGNED' : 'INT';
      case 'BIGINT':
        return column.isUnsigned ? 'BIGINT UNSIGNED' : 'BIGINT';
      case 'TINYINT':
        return column.isUnsigned ? 'TINYINT UNSIGNED' : 'TINYINT';
      case 'SMALLINT':
        return column.isUnsigned ? 'SMALLINT UNSIGNED' : 'SMALLINT';
      case 'MEDIUMINT':
        return column.isUnsigned ? 'MEDIUMINT UNSIGNED' : 'MEDIUMINT';
      case 'FLOAT':
        return column.isUnsigned ? 'FLOAT UNSIGNED' : 'FLOAT';
      case 'DOUBLE':
        return column.isUnsigned ? 'DOUBLE UNSIGNED' : 'DOUBLE';
      case 'DECIMAL':
        // Assuming length stores precision and scale if needed, but usually passed differently.
        // For now, default to DECIMAL(8, 2) if not specified or just DECIMAL.
        return 'DECIMAL';
      case 'BOOLEAN':
      case 'BOOL':
        return 'TINYINT(1)';
      case 'JSON':
      case 'ARRAY':
        return 'JSON';
      case 'TEXT':
        return 'TEXT';
      case 'LONGTEXT':
        return 'LONGTEXT';
      case 'MEDIUMTEXT':
        return 'MEDIUMTEXT';
      case 'DATE':
        return 'DATE';
      case 'DATETIME':
        return 'DATETIME';
      case 'TIMESTAMP':
        return 'TIMESTAMP';
      case 'TIME':
        return 'TIME';
      case 'YEAR':
        return 'YEAR';
      case 'BINARY':
        return 'BINARY(${column.length ?? 255})';
      case 'VARBINARY':
        return 'VARBINARY(${column.length ?? 255})';
      case 'BLOB':
        return 'BLOB';
      case 'LONGBLOB':
        return 'LONGBLOB';
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
    String tableName,
    void Function(Blueprint table) callback,
  ) {
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

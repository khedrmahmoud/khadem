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

    // Charset & Collation
    if (column.charsetValue != null) {
      parts.add('CHARACTER SET ${column.charsetValue}');
    }
    if (column.collationValue != null) {
      parts.add('COLLATE ${column.collationValue}');
    }

    // 2. Nullability
    parts.add(column.isNullable ? 'NULL' : 'NOT NULL');

    // 3. Default Value
    if (column.defaultValue != null && column.generatedExpression == null) {
      parts.add(_compileDefault(column));
    }

    // 4. On Update Current Timestamp
    if (column.useCurrentOnUpdateValue) {
      parts.add('ON UPDATE CURRENT_TIMESTAMP');
    }

    // 5. Invisible (MySQL 8.0+)
    if (column.isInvisible) {
      parts.add('INVISIBLE');
    }

    // 6. Auto Increment
    if (column.isAutoIncrement) {
      parts.add('AUTO_INCREMENT');
    }

    // 7. Primary Key (Inline)
    if (column.isPrimary) {
      parts.add('PRIMARY KEY');
    } else if (column.isUnique) {
      parts.add('UNIQUE');
    }

    // 8. Comments
    if (column.commentValue != null) {
      parts.add("COMMENT '${column.commentValue!.replaceAll("'", "\\'")}'");
    }

    // 9. Check Constraints (MySQL 8.0.16+)
    if (column.checkConstraint != null) {
      parts.add('CHECK (${column.checkConstraint})');
    }

    // 10. Positioning
    if (column.isFirst) {
      parts.add('FIRST');
    } else if (column.afterColumn != null) {
      parts.add('AFTER `${column.afterColumn}`');
    }

    return parts.join(' ');
  }

  String _compileDefault(ColumnDefinition column) {
    final value = column.defaultValue;
    
    if (column.isDefaultRaw) {
      return 'DEFAULT $value';
    }

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
        return 'VARCHAR(${column.lengthValue ?? 255})';
      case 'CHAR':
        return 'CHAR(${column.lengthValue ?? 255})';
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
        if (column.precisionValue != null && column.scaleValue != null) {
          return 'FLOAT(${column.precisionValue}, ${column.scaleValue}) ${column.isUnsigned ? 'UNSIGNED' : ''}'.trim();
        }
        return column.isUnsigned ? 'FLOAT UNSIGNED' : 'FLOAT';
      case 'DOUBLE':
        if (column.precisionValue != null && column.scaleValue != null) {
          return 'DOUBLE(${column.precisionValue}, ${column.scaleValue}) ${column.isUnsigned ? 'UNSIGNED' : ''}'.trim();
        }
        return column.isUnsigned ? 'DOUBLE UNSIGNED' : 'DOUBLE';
      case 'DECIMAL':
        if (column.precisionValue != null && column.scaleValue != null) {
          return 'DECIMAL(${column.precisionValue}, ${column.scaleValue}) ${column.isUnsigned ? 'UNSIGNED' : ''}'.trim();
        }
        return 'DECIMAL(8, 2)'; // Default
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
        return 'BINARY(${column.lengthValue ?? 255})';
      case 'VARBINARY':
        return 'VARBINARY(${column.lengthValue ?? 255})';
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

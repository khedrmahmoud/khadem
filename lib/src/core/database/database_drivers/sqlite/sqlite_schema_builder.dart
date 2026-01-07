import '../../../../contracts/database/schema_builder.dart';
import '../../schema/blueprint.dart';
import '../../schema/column_definition.dart';

class SQLiteSchemaBuilder implements SchemaBuilder {
  final List<String> _queries = [];

  @override
  List<String> get queries => _queries;

  @override
  void create(String tableName, void Function(Blueprint table) callback) {
    final blueprint = Blueprint(tableName);
    callback(blueprint);

    final columnSQLs = blueprint.columns.map(_columnToSQL).toList();
    final constraints = _generateTableConstraints(blueprint.columns, tableName);

    final fullSQL = [
      ...columnSQLs,
      ...constraints,
    ].join(', ');

    _queries.add('CREATE TABLE "$tableName" ($fullSQL);');

    // Add Indexes
    for (final column in blueprint.columns) {
      if (column.isIndexed) {
        _queries.add(
            'CREATE INDEX "${tableName}_${column.name}_index" ON "$tableName" ("${column.name}");',);
      }
    }
  }

  @override
  void createIfNotExists(
    String tableName,
    void Function(Blueprint table) callback,
  ) {
    final blueprint = Blueprint(tableName);
    callback(blueprint);

    final columnSQLs = blueprint.columns.map(_columnToSQL).toList();
    final constraints = _generateTableConstraints(blueprint.columns, tableName);

    final fullSQL = [
      ...columnSQLs,
      ...constraints,
    ].join(', ');

    _queries.add('CREATE TABLE IF NOT EXISTS "$tableName" ($fullSQL);');

    // Add Indexes
    for (final column in blueprint.columns) {
      if (column.isIndexed) {
        _queries.add(
            'CREATE INDEX IF NOT EXISTS "${tableName}_${column.name}_index" ON "$tableName" ("${column.name}");',);
      }
    }
  }

  @override
  void drop(String tableName) {
    _queries.add('DROP TABLE "$tableName";');
  }

  @override
  void dropIfExists(String tableName) {
    _queries.add('DROP TABLE IF EXISTS "$tableName";');
  }

  void clear() {
    _queries.clear();
  }

  // ===========================================================================
  // Column Compilation
  // ===========================================================================

  String _columnToSQL(ColumnDefinition column) {
    final parts = <String>[];

    // 1. Name
    parts.add('"${column.name}"');

    // 2. Type
    parts.add(_getType(column));

    // 3. Primary Key & Auto Increment
    // In SQLite, AUTOINCREMENT is only allowed on INTEGER PRIMARY KEY
    if (column.isPrimary && column.isAutoIncrement && _isInteger(column)) {
      parts.add('PRIMARY KEY AUTOINCREMENT');
    } else if (column.isPrimary) {
      parts.add('PRIMARY KEY');
    }

    // 4. Nullability
    if (!column.isNullable && !column.isPrimary) {
      parts.add('NOT NULL');
    } else if (column.isNullable) {
      parts.add('NULL');
    }

    // 5. Default Value
    if (column.defaultValue != null || column.isDefaultRaw) {
      parts.add(_compileDefault(column));
    }

    // 6. Unique (Inline)
    if (column.isUnique && !column.isPrimary) {
      parts.add('UNIQUE');
    }

    // 7. Check Constraints
    if (column.checkConstraint != null) {
      parts.add('CHECK (${column.checkConstraint})');
    }

    // 8. Collation
    if (column.collationValue != null) {
      parts.add('COLLATE ${column.collationValue}');
    }

    // 9. Generated Columns (SQLite 3.31+)
    if (column.generatedExpression != null) {
      parts.add('GENERATED ALWAYS AS (${column.generatedExpression})');
      parts.add(column.isStoredGenerated ? 'STORED' : 'VIRTUAL');
    }

    return parts.join(' ');
  }

  String _getType(ColumnDefinition column) {
    final type = column.type.toUpperCase();

    switch (type) {
      case 'INT':
      case 'INTEGER':
      case 'TINYINT':
      case 'SMALLINT':
      case 'MEDIUMINT':
      case 'BIGINT':
      case 'BOOLEAN':
      case 'BOOL':
        return 'INTEGER';

      case 'FLOAT':
      case 'DOUBLE':
      case 'REAL':
        return 'REAL';

      case 'DECIMAL':
      case 'NUMERIC':
        if (column.precisionValue != null && column.scaleValue != null) {
          return 'DECIMAL(${column.precisionValue}, ${column.scaleValue})';
        }
        return 'NUMERIC';

      case 'DATE':
      case 'DATETIME':
      case 'TIMESTAMP':
      case 'TIME':
        // SQLite doesn't have a dedicated date/time type.
        // TEXT, REAL, or INTEGER are used. We default to TEXT (ISO8601).
        return 'TEXT';

      case 'BLOB':
      case 'BINARY':
      case 'VARBINARY':
      case 'LONGBLOB':
        return 'BLOB';

      case 'JSON':
      case 'ARRAY':
        // JSON is stored as TEXT
        return 'TEXT';

      case 'VARCHAR':
      case 'CHAR':
      case 'TEXT':
      case 'MEDIUMTEXT':
      case 'LONGTEXT':
      case 'ENUM':
        return 'TEXT';

      default:
        return type;
    }
  }

  bool _isInteger(ColumnDefinition column) {
    final type = column.type.toUpperCase();
    return ['INT', 'INTEGER', 'BIGINT', 'TINYINT', 'SMALLINT', 'MEDIUMINT']
        .contains(type);
  }

  String _compileDefault(ColumnDefinition column) {
    if (column.isDefaultRaw) {
      return 'DEFAULT ${column.defaultValue}';
    }

    final value = column.defaultValue;

    if (value == null) {
      return 'DEFAULT NULL';
    }

    if (value is bool) {
      return 'DEFAULT ${value ? 1 : 0}';
    }

    if (value is num) {
      return 'DEFAULT $value';
    }

    if (value is String) {
      if (value.toUpperCase() == 'CURRENT_TIMESTAMP') {
        return 'DEFAULT CURRENT_TIMESTAMP';
      }
      return "DEFAULT '$value'";
    }

    return "DEFAULT '$value'";
  }

  // ===========================================================================
  // Table Constraints
  // ===========================================================================

  List<String> _generateTableConstraints(
      List<ColumnDefinition> columns, String tableName,) {
    final constraints = <String>[];

    for (final column in columns) {
      // Foreign Keys
      if (column.foreignTable != null && column.foreignKey != null) {
        final onDelete = column.onDeleteAction != null
            ? ' ON DELETE ${column.onDeleteAction!.toUpperCase()}'
            : '';
        final onUpdate = column.onUpdateAction != null
            ? ' ON UPDATE ${column.onUpdateAction!.toUpperCase()}'
            : '';

        constraints.add(
          'FOREIGN KEY ("${column.name}") REFERENCES "${column.foreignTable}" ("${column.foreignKey}")$onDelete$onUpdate',
        );
      }
    }

    return constraints;
  }
}

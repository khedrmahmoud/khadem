import 'column_definition.dart';

/// Used to define the schema of a database table
class Blueprint {
  final String table;
  final List<ColumnDefinition> columns = [];
  final List<IndexDefinition> indexes = [];
  final List<IndexDefinition> uniques = [];
  IndexDefinition? primaryKey;

  Blueprint(this.table);

  /// Primary Auto-Increment ID
  ColumnDefinition id([String name = 'id']) {
    final col =
        ColumnDefinition(name, 'BIGINT').primary().autoIncrement().unsigned();
    columns.add(col);
    return col;
  }

  /// Auto-incrementing INT primary key
  ColumnDefinition increments([String name = 'id']) {
    final col = ColumnDefinition(name, 'INT').primary().autoIncrement();
    columns.add(col);
    return col;
  }

  /// Auto-incrementing BIGINT primary key
  ColumnDefinition bigIncrements([String name = 'id']) {
    return id(name);
  }

  /// String (VARCHAR)
  ColumnDefinition string(String name, {int length = 255}) {
    final col = ColumnDefinition(name, 'VARCHAR').length(length);
    columns.add(col);
    return col;
  }

  /// Char (CHAR)
  ColumnDefinition char(String name, {int length = 255}) {
    final col = ColumnDefinition(name, 'CHAR').length(length);
    columns.add(col);
    return col;
  }

  /// Text (TEXT)
  ColumnDefinition text(String name) {
    final col = ColumnDefinition(name, 'TEXT');
    columns.add(col);
    return col;
  }

  /// Tiny Text (TINYTEXT)
  ColumnDefinition tinyText(String name) {
    final col = ColumnDefinition(name, 'TINYTEXT');
    columns.add(col);
    return col;
  }

  /// Medium Text (MEDIUMTEXT)
  ColumnDefinition mediumText(String name) {
    final col = ColumnDefinition(name, 'MEDIUMTEXT');
    columns.add(col);
    return col;
  }

  /// Long Text (LONGTEXT)
  ColumnDefinition longText(String name) {
    final col = ColumnDefinition(name, 'LONGTEXT');
    columns.add(col);
    return col;
  }

  /// Boolean
  ColumnDefinition boolean(String name) {
    final col = ColumnDefinition(name, 'BOOLEAN');
    columns.add(col);
    return col;
  }

  /// Big Integer (BIGINT)
  ColumnDefinition bigInteger(String name) {
    final col = ColumnDefinition(name, 'BIGINT');
    columns.add(col);
    return col;
  }

  /// Tiny Integer (TINYINT)
  ColumnDefinition tinyInteger(String name) {
    final col = ColumnDefinition(name, 'TINYINT');
    columns.add(col);
    return col;
  }

  /// Small Integer (SMALLINT)
  ColumnDefinition smallInteger(String name) {
    final col = ColumnDefinition(name, 'SMALLINT');
    columns.add(col);
    return col;
  }

  /// Medium Integer (MEDIUMINT)
  ColumnDefinition mediumInteger(String name) {
    final col = ColumnDefinition(name, 'MEDIUMINT');
    columns.add(col);
    return col;
  }

  /// Unsigned Big Integer (BIGINT)
  ColumnDefinition unsignedBigInteger(String name) {
    final col = ColumnDefinition(name, 'BIGINT').unsigned();
    columns.add(col);
    return col;
  }

  /// Integer (INT)
  ColumnDefinition integer(String name) {
    final col = ColumnDefinition(name, 'INT');
    columns.add(col);
    return col;
  }

  /// Unsigned Integer (INT)
  ColumnDefinition unsignedInteger(String name) {
    final col = ColumnDefinition(name, 'INT').unsigned();
    columns.add(col);
    return col;
  }

  /// Float (FLOAT)
  ColumnDefinition float(String name, {int? total, int? places}) {
    final col = ColumnDefinition(name, 'FLOAT');
    if (total != null) col.total(total, places ?? 0);
    columns.add(col);
    return col;
  }

  /// Double (DOUBLE)
  ColumnDefinition double(String name, {int? total, int? places}) {
    final col = ColumnDefinition(name, 'DOUBLE');
    if (total != null) col.total(total, places ?? 0);
    columns.add(col);
    return col;
  }

  /// Decimal (DECIMAL)
  ColumnDefinition decimal(String name, {int? total, int? places}) {
    final col = ColumnDefinition(name, 'DECIMAL');
    if (total != null) col.total(total, places ?? 0);
    columns.add(col);
    return col;
  }

  /// JSON
  ColumnDefinition json(String name) {
    final col = ColumnDefinition(name, 'JSON');
    columns.add(col);
    return col;
  }

  /// JSONB (alias to JSON)
  ColumnDefinition jsonb(String name) {
    return json(name);
  }

  /// Array (ARRAY)
  ColumnDefinition array(String name) {
    final col = ColumnDefinition(name, 'ARRAY');
    columns.add(col);
    return col;
  }

  /// Date
  ColumnDefinition date(String name) {
    final col = ColumnDefinition(name, 'DATE');
    columns.add(col);
    return col;
  }

  /// DateTime
  ColumnDefinition dateTime(String name) {
    final col = ColumnDefinition(name, 'DATETIME');
    columns.add(col);
    return col;
  }

  /// Time
  ColumnDefinition time(String name) {
    final col = ColumnDefinition(name, 'TIME');
    columns.add(col);
    return col;
  }

  /// Year
  ColumnDefinition year(String name) {
    final col = ColumnDefinition(name, 'YEAR');
    columns.add(col);
    return col;
  }

  /// Timestamp
  ColumnDefinition timestamp(String name) {
    final col = ColumnDefinition(name, 'TIMESTAMP');
    columns.add(col);
    return col;
  }

  /// Timestamp (alias)
  ColumnDefinition timestampTz(String name) {
    return timestamp(name);
  }

  /// Adds created_at & updated_at timestamps
  void timestamps({bool useCurrent = false, bool useCurrentOnUpdate = true}) {
    final created = timestamp('created_at');
    final updated = timestamp('updated_at');
    if (useCurrent) {
      created.useCurrent();
      updated.useCurrent();
    }
    if (useCurrentOnUpdate) {
      updated.useCurrentOnUpdate();
    }
  }

  /// Adds created_at & updated_at timestamps (alias)
  void timestampsTz({bool useCurrent = false, bool useCurrentOnUpdate = true}) {
    timestamps(useCurrent: useCurrent, useCurrentOnUpdate: useCurrentOnUpdate);
  }

  /// Adds deleted_at timestamp (soft delete)
  void softDeletes({String name = 'deleted_at'}) {
    timestamp(name).nullable();
  }

  /// Adds morphs (polymorphic relations)
  void morphs(String name) {
    string('${name}_type');
    bigInteger('${name}_id').unsigned();
  }

  /// Adds nullable morphs (polymorphic relations)
  void nullableMorphs(String name) {
    string('${name}_type').nullable();
    bigInteger('${name}_id').unsigned().nullable();
  }

  /// Foreign ID (unsigned BIGINT)
  ColumnDefinition foreignId(String name) {
    return bigInteger(name).unsigned();
  }

  /// Foreign ID with constraint shortcut
  ColumnDefinition foreignIdFor(
    String relatedTable, {
    String? column,
    String key = 'id',
  }) {
    final col = foreignId(column ?? '${relatedTable}_id');
    col.foreign(relatedTable, key: key);
    return col;
  }

  /// UUID column (CHAR(36))
  ColumnDefinition uuid(String name) {
    final col = ColumnDefinition(name, 'CHAR').length(36);
    columns.add(col);
    return col;
  }

  /// UUID primary key (CHAR(36))
  ColumnDefinition uuidPrimary([String name = 'uuid']) {
    final col = uuid(name).primary();
    return col;
  }

  /// Foreign UUID (CHAR(36))
  ColumnDefinition foreignUuid(String name) {
    final col = ColumnDefinition(name, 'CHAR').length(36);
    columns.add(col);
    return col;
  }

  /// Foreign UUID with constraint shortcut
  ColumnDefinition foreignUuidFor(
    String relatedTable, {
    String? column,
    String key = 'uuid',
  }) {
    final col = foreignUuid(column ?? '${relatedTable}_uuid');
    col.foreign(relatedTable, key: key);
    return col;
  }

  /// ENUM column
  ColumnDefinition enumColumn(String name, List<String> values) {
    final col = ColumnDefinition(name, 'ENUM').enumVal(values);
    columns.add(col);
    return col;
  }

  /// Binary
  ColumnDefinition binary(String name, {int length = 255}) {
    final col = ColumnDefinition(name, 'BINARY').length(length);
    columns.add(col);
    return col;
  }

  /// VarBinary
  ColumnDefinition varBinary(String name, {int length = 255}) {
    final col = ColumnDefinition(name, 'VARBINARY').length(length);
    columns.add(col);
    return col;
  }

  /// Blob
  ColumnDefinition blob(String name) {
    final col = ColumnDefinition(name, 'BLOB');
    columns.add(col);
    return col;
  }

  /// Medium Blob
  ColumnDefinition mediumBlob(String name) {
    final col = ColumnDefinition(name, 'MEDIUMBLOB');
    columns.add(col);
    return col;
  }

  /// Long Blob
  ColumnDefinition longBlob(String name) {
    final col = ColumnDefinition(name, 'LONGBLOB');
    columns.add(col);
    return col;
  }

  /// Add an index on columns
  void index(List<String> columns, {String? name}) {
    indexes.add(IndexDefinition(columns, name: name));
  }

  /// Add a unique index on columns
  void unique(List<String> columns, {String? name}) {
    uniques.add(IndexDefinition(columns, name: name));
  }

  /// Add a primary key for columns
  void primary(List<String> columns, {String? name}) {
    primaryKey = IndexDefinition(columns, name: name);
  }

  /// Adds custom column directly
  void raw(ColumnDefinition column) {
    columns.add(column);
  }
}

class IndexDefinition {
  final List<String> columns;
  final String? name;

  IndexDefinition(this.columns, {this.name});
}

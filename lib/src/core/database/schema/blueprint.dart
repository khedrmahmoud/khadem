import 'column_definition.dart';

/// Used to define the schema of a database table
class Blueprint {
  final String table;
  final List<ColumnDefinition> columns = [];

  Blueprint(this.table);

  /// Primary Auto-Increment ID
  ColumnDefinition id([String name = 'id']) {
    final col =
        ColumnDefinition(name, 'BIGINT').primary().autoIncrement().unsigned();
    columns.add(col);
    return col;
  }

  /// String (VARCHAR)
  ColumnDefinition string(String name, {int length = 255}) {
    final col = ColumnDefinition(name, 'VARCHAR').lengthVal(length);
    columns.add(col);
    return col;
  }

  /// Text (TEXT)
  ColumnDefinition text(String name) {
    final col = ColumnDefinition(name, 'TEXT');
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

  /// Integer (INT)
  ColumnDefinition integer(String name) {
    final col = ColumnDefinition(name, 'INT');
    columns.add(col);
    return col;
  }

  /// Float (FLOAT)
  ColumnDefinition float(String name) {
    final col = ColumnDefinition(name, 'FLOAT');
    columns.add(col);
    return col;
  }

  /// JSON
  ColumnDefinition json(String name) {
    final col = ColumnDefinition(name, 'JSON');
    columns.add(col);
    return col;
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

  /// Timestamp
  ColumnDefinition timestamp(String name) {
    final col = ColumnDefinition(name, 'TIMESTAMP');
    columns.add(col);
    return col;
  }

  /// Adds created_at & updated_at timestamps
  void timestamps() {
    timestamp('created_at');
    timestamp('updated_at');
  }

  /// Adds deleted_at timestamp (soft delete)
  void softDeletes() {
    timestamp('deleted_at').nullable();
  }

  /// Adds morphs (polymorphic relations)
  void morphs(String name) {
    string('${name}_type');
    bigInteger('${name}_id').unsigned();
  }

  /// Foreign ID (unsigned BIGINT)
  ColumnDefinition foreignId(String name) {
    return bigInteger(name).unsigned();
  }

  /// ENUM column
  ColumnDefinition enumColumn(String name, List<String> values) {
    final col = ColumnDefinition(name, 'ENUM').enumVal(values);
    columns.add(col);
    return col;
  }

  /// Adds custom column directly
  void raw(ColumnDefinition column) {
    columns.add(column);
  }
}

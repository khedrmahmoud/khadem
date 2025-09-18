/// Represents a single column in a database table definition.
///
/// This class provides a fluent API for defining column properties, such as
/// primary keys, unique constraints, nullable columns, unsigned integers,
/// auto-incrementing columns, default values, comments, length constraints,
/// indexes, foreign keys, check constraints, and generated/computed columns.
class ColumnDefinition {
  /// The name of the column.
  final String name;

  /// The type of the column (e.g. 'INT', 'VARCHAR(255)', etc.).
  final String type;

  /// Whether the column is a primary key.
  bool isPrimary = false;

  /// Whether the column has a unique constraint.
  bool isUnique = false;

  /// Whether the column allows null values.
  bool isNullable = false;

  /// Whether the column is an unsigned integer.
  bool isUnsigned = false;

  /// Whether the column auto-increments.
  bool isAutoIncrement = false;

  /// Whether the column has an index.
  bool isIndexed = false;

  /// The default value for the column.
  dynamic defaultValue;

  /// The length of the column (for string types).
  int? length;

  /// A comment for the column.
  String? comment;

  /// The values for an ENUM column.
  List<String>? enumValues;

  /// The foreign table for the column.
  String? foreignTable;

  /// The foreign key for the column.
  String? foreignKey;

  /// The action to take when the foreign key is deleted.
  String? onDeleteAction;

  /// The action to take when the foreign key is updated.
  String? onUpdateAction;

  /// The expression for a generated/computed column.
  String? generatedExpression;

  /// Whether the generated column is stored.
  bool isStoredGenerated = false;

  /// The check constraint for the column.
  String? checkConstraint;

  /// Creates a new column definition.
  ColumnDefinition(this.name, this.type);

  /// Specifies the column as a primary key.
  ColumnDefinition primary() {
    isPrimary = true;
    return this;
  }

  /// Specifies the column as unique.
  ColumnDefinition unique() {
    isUnique = true;
    return this;
  }

  /// Specifies the column as nullable.
  ColumnDefinition nullable() {
    isNullable = true;
    return this;
  }

  /// Specifies the column as an unsigned integer.
  ColumnDefinition unsigned() {
    isUnsigned = true;
    return this;
  }

  /// Specifies the column as auto-incrementing.
  ColumnDefinition autoIncrement() {
    isAutoIncrement = true;
    return this;
  }

  /// Specifies a default value for the column.
  ColumnDefinition defaultVal(dynamic value) {
    defaultValue = value;
    return this;
  }

  /// Specifies a comment for the column.
  ColumnDefinition commentText(String text) {
    comment = text;
    return this;
  }

  /// Specifies the length of the column (for string types).
  ColumnDefinition lengthVal(int len) {
    length = len;
    return this;
  }

  /// Specifies an index for the column.
  ColumnDefinition index() {
    isIndexed = true;
    return this;
  }

  /// Specifies a foreign key for the column.
  ColumnDefinition foreign(String table, {String key = 'id'}) {
    foreignTable = table;
    foreignKey = key;
    return this;
  }

  /// Specifies the action to take when the foreign key is deleted.
  ColumnDefinition onDelete(String action) {
    onDeleteAction = action;
    return this;
  }

  /// Specifies the action to take when the foreign key is updated.
  ColumnDefinition onUpdate(String action) {
    onUpdateAction = action;
    return this;
  }

  /// Specifies the values for an ENUM column.
  ColumnDefinition enumVal(List<String> values) {
    enumValues = values;
    return this;
  }

  /// Specifies a check constraint for the column.
  ColumnDefinition check(String condition) {
    checkConstraint = condition;
    return this;
  }

  /// Specifies a generated/computed column.
  ///
  /// Example:
  ///     generatedAs('now()')
  ///
  /// `stored` parameter:
  /// - `true` -> stored generated (stored in the database)
  /// - `false` -> virtual generated (generated in the application)
  ColumnDefinition generatedAs(String expression, {bool stored = false}) {
    generatedExpression = expression;
    isStoredGenerated = stored;
    return this;
  }
}

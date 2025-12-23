/// Represents a single column in a database table definition.
class ColumnDefinition {
  /// The name of the column.
  final String name;

  /// The type of the column (e.g. 'INT', 'VARCHAR', 'DECIMAL').
  final String type;

  // ---------------------------------------------------------------------------
  // Modifiers
  // ---------------------------------------------------------------------------
  bool isNullable = false;
  bool isUnsigned = false;
  bool isAutoIncrement = false;
  bool isPrimary = false;
  bool isUnique = false;
  bool isIndexed = false;
  bool isInvisible = false;

  // ---------------------------------------------------------------------------
  // Default Value
  // ---------------------------------------------------------------------------
  dynamic defaultValue;
  bool isDefaultRaw = false;

  // ---------------------------------------------------------------------------
  // String / Text Options
  // ---------------------------------------------------------------------------
  int? lengthValue;
  String? charsetValue;
  String? collationValue;

  // ---------------------------------------------------------------------------
  // Numeric Options (Decimal, Float)
  // ---------------------------------------------------------------------------
  int? precisionValue;
  int? scaleValue;

  // ---------------------------------------------------------------------------
  // Foreign Key Options
  // ---------------------------------------------------------------------------
  String? foreignTable;
  String? foreignKey;
  String? onDeleteAction;
  String? onUpdateAction;

  // ---------------------------------------------------------------------------
  // Generated Columns / Expressions
  // ---------------------------------------------------------------------------
  String? generatedExpression;
  bool isStoredGenerated = false;

  // ---------------------------------------------------------------------------
  // Timestamp Options
  // ---------------------------------------------------------------------------
  bool useCurrentOnUpdateValue = false;

  // ---------------------------------------------------------------------------
  // Positioning (MySQL)
  // ---------------------------------------------------------------------------
  String? afterColumn;
  bool isFirst = false;

  // ---------------------------------------------------------------------------
  // Metadata & Constraints
  // ---------------------------------------------------------------------------
  String? commentValue;
  String? checkConstraint;
  List<String>? enumValues;

  // ---------------------------------------------------------------------------
  // Migration / Schema Change Options
  // ---------------------------------------------------------------------------
  String? oldName;

  /// Creates a new column definition.
  ColumnDefinition(this.name, this.type);

  // ===========================================================================
  // Modifier Methods
  // ===========================================================================

  /// Specifies the column as nullable.
  ColumnDefinition nullable([bool value = true]) {
    isNullable = value;
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

  /// Specifies an index for the column.
  ColumnDefinition index() {
    isIndexed = true;
    return this;
  }

  /// Specifies the column as invisible (MySQL 8.0+).
  ColumnDefinition invisible() {
    isInvisible = true;
    return this;
  }

  // ===========================================================================
  // Default Value Methods
  // ===========================================================================

  /// Specifies a default value for the column.
  ///
  /// [value] can be a String, num, bool, or DateTime.
  ColumnDefinition defaultsTo(dynamic value) {
    defaultValue = value;
    isDefaultRaw = false;
    return this;
  }

  /// Alias for [defaultsTo].
  ColumnDefinition defaultVal(dynamic value) => defaultsTo(value);

  /// Specifies a raw SQL default value for the column.
  ///
  /// Example: `defaultRaw('CURRENT_TIMESTAMP')`
  ColumnDefinition defaultRaw(String sql) {
    defaultValue = sql;
    isDefaultRaw = true;
    return this;
  }

  // ===========================================================================
  // String / Text Methods
  // ===========================================================================

  /// Specifies the length of the column (for string types).
  ColumnDefinition length(int len) {
    lengthValue = len;
    return this;
  }

  /// Specifies the character set for the column.
  ColumnDefinition charset(String charset) {
    charsetValue = charset;
    return this;
  }

  /// Specifies the collation for the column.
  ColumnDefinition collation(String collation) {
    collationValue = collation;
    return this;
  }

  // ===========================================================================
  // Numeric Methods
  // ===========================================================================

  /// Specifies the precision and scale for decimal columns.
  ColumnDefinition total(int total, [int places = 0]) {
    precisionValue = total;
    scaleValue = places;
    return this;
  }

  // ===========================================================================
  // Foreign Key Methods
  // ===========================================================================

  /// Specifies a foreign key constraint.
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

  /// Cascade on delete.
  ColumnDefinition cascadeOnDelete() => onDelete('CASCADE');

  /// Cascade on update.
  ColumnDefinition cascadeOnUpdate() => onUpdate('CASCADE');

  /// Set null on delete.
  ColumnDefinition nullOnDelete() => onDelete('SET NULL');

  /// Restrict on delete.
  ColumnDefinition restrictOnDelete() => onDelete('RESTRICT');

  // ===========================================================================
  // Generated Column Methods
  // ===========================================================================

  /// Create a virtual generated column.
  ColumnDefinition virtualAs(String expression) {
    generatedExpression = expression;
    isStoredGenerated = false;
    return this;
  }

  /// Create a stored generated column.
  ColumnDefinition storedAs(String expression) {
    generatedExpression = expression;
    isStoredGenerated = true;
    return this;
  }

  // ===========================================================================
  // Timestamp Methods
  // ===========================================================================

  /// Set the TIMESTAMP column to use CURRENT_TIMESTAMP as default.
  ColumnDefinition useCurrent() {
    return defaultRaw('CURRENT_TIMESTAMP');
  }

  /// Set the TIMESTAMP column to use CURRENT_TIMESTAMP on update.
  ColumnDefinition useCurrentOnUpdate() {
    useCurrentOnUpdateValue = true;
    return this;
  }

  /// Alias for [useCurrentOnUpdate].
  ColumnDefinition onUpdateCurrentTimestamp() => useCurrentOnUpdate();

  // ===========================================================================
  // Positioning Methods
  // ===========================================================================

  /// Place the column "after" another column.
  ColumnDefinition after(String column) {
    afterColumn = column;
    return this;
  }

  /// Place the column "first" in the table.
  ColumnDefinition first() {
    isFirst = true;
    return this;
  }

  // ===========================================================================
  // Metadata & Other Methods
  // ===========================================================================

  /// Specifies a comment for the column.
  ColumnDefinition comment(String text) {
    commentValue = text;
    return this;
  }

  /// Specifies a check constraint for the column.
  ColumnDefinition check(String condition) {
    checkConstraint = condition;
    return this;
  }

  /// Specifies the values for an ENUM column.
  ColumnDefinition enumVal(List<String> values) {
    enumValues = values;
    return this;
  }

  /// Rename the column from an old name (used in migrations).
  ColumnDefinition from(String oldName) {
    this.oldName = oldName;
    return this;
  }
}

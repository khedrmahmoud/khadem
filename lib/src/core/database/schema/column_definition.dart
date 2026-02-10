/// Represents a single column in a database table definition.
class ColumnDefinition {
  /// The name of the column.
  final String name;

  /// The type of the column (e.g. 'INT', 'VARCHAR', 'DECIMAL').
  final String type;

  // ---------------------------------------------------------------------------
  // Modifiers
  // ---------------------------------------------------------------------------
  bool _isNullable = false;
  bool _isUnsigned = false;
  bool _isAutoIncrement = false;
  bool _isPrimary = false;
  bool _isUnique = false;
  bool _isIndexed = false;
  bool _isInvisible = false;

  // ---------------------------------------------------------------------------
  // Default Value
  // ---------------------------------------------------------------------------
  dynamic _defaultValue;
  bool _isDefaultRaw = false;

  // ---------------------------------------------------------------------------
  // String / Text Options
  // ---------------------------------------------------------------------------
  int? _lengthValue;
  String? _charsetValue;
  String? _collationValue;

  // ---------------------------------------------------------------------------
  // Numeric Options (Decimal, Float)
  // ---------------------------------------------------------------------------
  int? _precisionValue;
  int? _scaleValue;

  // ---------------------------------------------------------------------------
  // Foreign Key Options
  // ---------------------------------------------------------------------------
  String? _foreignTable;
  String? _foreignKey;
  String? _onDeleteAction;
  String? _onUpdateAction;

  // ---------------------------------------------------------------------------
  // Generated Columns / Expressions
  // ---------------------------------------------------------------------------
  String? _generatedExpression;
  bool _isStoredGenerated = false;

  // ---------------------------------------------------------------------------
  // Timestamp Options
  // ---------------------------------------------------------------------------
  bool _useCurrentOnUpdateValue = false;

  // ---------------------------------------------------------------------------
  // Positioning (MySQL)
  // ---------------------------------------------------------------------------
  String? _afterColumn;
  bool _isFirst = false;

  // ---------------------------------------------------------------------------
  // Metadata & Constraints
  // ---------------------------------------------------------------------------
  String? _commentValue;
  String? _checkConstraint;
  List<String>? _enumValues;

  // ---------------------------------------------------------------------------
  // Migration / Schema Change Options
  // ---------------------------------------------------------------------------
  String? _oldName;

  /// Creates a new column definition.
  ColumnDefinition(this.name, this.type);

  // ===========================================================================
  // Readonly Accessors
  // ===========================================================================

  bool get isNullable => _isNullable;
  bool get isUnsigned => _isUnsigned;
  bool get isAutoIncrement => _isAutoIncrement;
  bool get isPrimary => _isPrimary;
  bool get isUnique => _isUnique;
  bool get isIndexed => _isIndexed;
  bool get isInvisible => _isInvisible;

  dynamic get defaultValue => _defaultValue;
  bool get isDefaultRaw => _isDefaultRaw;

  int? get lengthValue => _lengthValue;
  String? get charsetValue => _charsetValue;
  String? get collationValue => _collationValue;

  int? get precisionValue => _precisionValue;
  int? get scaleValue => _scaleValue;

  String? get foreignTable => _foreignTable;
  String? get foreignKey => _foreignKey;
  String? get onDeleteAction => _onDeleteAction;
  String? get onUpdateAction => _onUpdateAction;

  String? get generatedExpression => _generatedExpression;
  bool get isStoredGenerated => _isStoredGenerated;

  bool get useCurrentOnUpdateValue => _useCurrentOnUpdateValue;

  String? get afterColumn => _afterColumn;
  bool get isFirst => _isFirst;

  String? get commentValue => _commentValue;
  String? get checkConstraint => _checkConstraint;
  List<String>? get enumValues => _enumValues;

  String? get oldName => _oldName;

  // ===========================================================================
  // Modifier Methods
  // ===========================================================================

  /// Specifies the column as nullable.
  ColumnDefinition nullable([bool value = true]) {
    _isNullable = value;
    return this;
  }

  /// Specifies the column as NOT NULL.
  ColumnDefinition required() => nullable(false);

  /// Specifies the column as an unsigned integer.
  ColumnDefinition unsigned() {
    _isUnsigned = true;
    return this;
  }

  /// Specifies the column as signed (removes UNSIGNED).
  ColumnDefinition signed() {
    _isUnsigned = false;
    return this;
  }

  /// Specifies the column as auto-incrementing.
  ColumnDefinition autoIncrement() {
    _isAutoIncrement = true;
    return this;
  }

  /// Specifies the column as a primary key.
  ColumnDefinition primary() {
    _isPrimary = true;
    return this;
  }

  /// Specifies the column as unique.
  ColumnDefinition unique() {
    _isUnique = true;
    return this;
  }

  /// Specifies an index for the column.
  ColumnDefinition index() {
    _isIndexed = true;
    return this;
  }

  /// Specifies the column as invisible (MySQL 8.0+).
  ColumnDefinition invisible() {
    _isInvisible = true;
    return this;
  }

  // ===========================================================================
  // Default Value Methods
  // ===========================================================================

  /// Specifies a default value for the column.
  ///
  /// [value] can be a String, num, bool, or DateTime.
  ColumnDefinition defaultsTo(dynamic value) {
    _defaultValue = value;
    _isDefaultRaw = false;
    return this;
  }

  /// Alias for [defaultsTo].
  ColumnDefinition defaultVal(dynamic value) => defaultsTo(value);

  /// Specifies a raw SQL default value for the column.
  ///
  /// Example: `defaultRaw('CURRENT_TIMESTAMP')`
  ColumnDefinition defaultRaw(String sql) {
    _defaultValue = sql;
    _isDefaultRaw = true;
    return this;
  }

  /// Default to NULL.
  ColumnDefinition defaultNull() => defaultsTo(null);

  /// Default to TRUE.
  ColumnDefinition defaultTrue() => defaultsTo(true);

  /// Default to FALSE.
  ColumnDefinition defaultFalse() => defaultsTo(false);

  /// Default to CURRENT_TIMESTAMP.
  ColumnDefinition defaultNow() => defaultRaw('CURRENT_TIMESTAMP');

  // ===========================================================================
  // String / Text Methods
  // ===========================================================================

  /// Specifies the length of the column (for string types).
  ColumnDefinition length(int len) {
    _lengthValue = len;
    return this;
  }

  /// Specifies the character set for the column.
  ColumnDefinition charset(String charset) {
    _charsetValue = charset;
    return this;
  }

  /// Specifies the collation for the column.
  ColumnDefinition collation(String collation) {
    _collationValue = collation;
    return this;
  }

  // ===========================================================================
  // Numeric Methods
  // ===========================================================================

  /// Specifies the precision and scale for decimal columns.
  ColumnDefinition total(int total, [int places = 0]) {
    _precisionValue = total;
    _scaleValue = places;
    return this;
  }

  // ===========================================================================
  // Foreign Key Methods
  // ===========================================================================

  /// Specifies a foreign key constraint.
  ColumnDefinition foreign(String table, {String key = 'id'}) {
    _foreignTable = table;
    _foreignKey = key;
    return this;
  }

  /// Alias for [foreign].
  ColumnDefinition references(String table, {String key = 'id'}) =>
      foreign(table, key: key);

  /// Specifies the action to take when the foreign key is deleted.
  ColumnDefinition onDelete(String action) {
    _onDeleteAction = action;
    return this;
  }

  /// Specifies the action to take when the foreign key is updated.
  ColumnDefinition onUpdate(String action) {
    _onUpdateAction = action;
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
    _generatedExpression = expression;
    _isStoredGenerated = false;
    return this;
  }

  /// Create a stored generated column.
  ColumnDefinition storedAs(String expression) {
    _generatedExpression = expression;
    _isStoredGenerated = true;
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
    _useCurrentOnUpdateValue = true;
    return this;
  }

  /// Alias for [useCurrentOnUpdate].
  ColumnDefinition onUpdateCurrentTimestamp() => useCurrentOnUpdate();

  // ===========================================================================
  // Positioning Methods
  // ===========================================================================

  /// Place the column "after" another column.
  ColumnDefinition after(String column) {
    _afterColumn = column;
    return this;
  }

  /// Place the column "first" in the table.
  ColumnDefinition first() {
    _isFirst = true;
    return this;
  }

  // ===========================================================================
  // Metadata & Other Methods
  // ===========================================================================

  /// Specifies a comment for the column.
  ColumnDefinition comment(String text) {
    _commentValue = text;
    return this;
  }

  /// Conditionally set a comment.
  ColumnDefinition commentIf(bool condition, String text) {
    if (condition) {
      comment(text);
    }
    return this;
  }

  /// Specifies a check constraint for the column.
  ColumnDefinition check(String condition) {
    _checkConstraint = condition;
    return this;
  }

  /// Specifies the values for an ENUM column.
  ColumnDefinition enumVal(List<String> values) {
    _enumValues = values;
    return this;
  }

  /// Rename the column from an old name (used in migrations).
  ColumnDefinition from(String oldName) {
    _oldName = oldName;
    return this;
  }
}

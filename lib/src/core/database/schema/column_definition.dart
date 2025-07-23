/// Represents a single column in a database table definition.
class ColumnDefinition {
  final String name;
  final String type;

  bool isPrimary = false;
  bool isUnique = false;
  bool isNullable = false;
  bool isUnsigned = false;
  bool isAutoIncrement = false;
  bool isIndexed = false;

  dynamic defaultValue;
  int? length;
  String? comment;

  // ENUM values
  List<String>? enumValues;

  // Foreign key
  String? foreignTable;
  String? foreignKey;
  String? onDeleteAction;
  String? onUpdateAction;

  // Generated / computed column
  String? generatedExpression;
  bool isStoredGenerated = false;

  // Check constraint
  String? checkConstraint;

  ColumnDefinition(this.name, this.type);

  ColumnDefinition primary() {
    isPrimary = true;
    return this;
  }

  ColumnDefinition unique() {
    isUnique = true;
    return this;
  }

  ColumnDefinition nullable() {
    isNullable = true;
    return this;
  }

  ColumnDefinition unsigned() {
    isUnsigned = true;
    return this;
  }

  ColumnDefinition autoIncrement() {
    isAutoIncrement = true;
    return this;
  }

  ColumnDefinition defaultVal(dynamic value) {
    defaultValue = value;
    return this;
  }

  ColumnDefinition commentText(String text) {
    comment = text;
    return this;
  }

  ColumnDefinition lengthVal(int len) {
    length = len;
    return this;
  }

  ColumnDefinition index() {
    isIndexed = true;
    return this;
  }

  ColumnDefinition foreign(String table, {String key = 'id'}) {
    foreignTable = table;
    foreignKey = key;
    return this;
  }

  ColumnDefinition onDelete(String action) {
    onDeleteAction = action;
    return this;
  }

  ColumnDefinition onUpdate(String action) {
    onUpdateAction = action;
    return this;
  }

  ColumnDefinition enumVal(List<String> values) {
    enumValues = values;
    return this;
  }

  ColumnDefinition check(String condition) {
    checkConstraint = condition;
    return this;
  }

  ColumnDefinition generatedAs(String expression, {bool stored = false}) {
    generatedExpression = expression;
    isStoredGenerated = stored;
    return this;
  }
}

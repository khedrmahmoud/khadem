import 'khadem_model.dart';

class DatabaseModel<T> {
  final KhademModel<T> model;

  DatabaseModel(this.model);

  Future<void> save() async {
    if (model.id != null) {
      await model.event.beforeUpdate();
      // Use parameterized query to prevent SQL injection
      await model.query
          .where('id', '=', model.id)
          .update(model.toDatabaseJson());
      await model.event.afterUpdate();
    } else {
      await model.event.beforeCreate();
      // Use parameterized query to prevent SQL injection
      final id = await model.query.insert(model.toDatabaseJson());
      model.id = id;
      await model.event.afterCreate();
    }
  }

  Future<void> delete() async {
    await model.event.beforeDelete();
    // Use parameterized query to prevent SQL injection
    await model.query.where('id', '=', model.id).delete();
    await model.event.afterDelete();
  }

  /// Finds a record by ID using parameterized query to prevent SQL injection
  Future<T?> findById(dynamic id) async {
    if (id == null) return null;

    // Use parameterized query to prevent SQL injection
    final results = await model.query.where('id', '=', id).limit(1).get();

    if (results.isEmpty) return null;

    return results.first;
  }

  /// Refreshes the current model instance from the database
  Future<void> refresh() async {
    if (model.id == null) {
      throw Exception('Cannot refresh a model without an ID');
    }

    final freshInstance = (await findById(model.id)) as KhademModel<T>?;
    if (freshInstance != null) {
      model.fromJson(freshInstance.toDatabaseJson());
    }
  }

  /// Finds records with validated conditions to prevent SQL injection
  Future<List<T>> findWhere(
    String column,
    String operator,
    dynamic value,
  ) async {
    // Validate column name to prevent SQL injection
    if (!_isValidColumn(column)) {
      throw ArgumentError('Invalid column name: $column');
    }

    // Validate operator
    if (!_isValidOperator(operator)) {
      throw ArgumentError('Invalid operator: $operator');
    }

    // Use parameterized query
    final results = await model.query.where(column, operator, value).get();

    return results;
  }

  /// Validates column name to prevent SQL injection
  bool _isValidColumn(String column) {
    // Allow only alphanumeric characters and underscores
    final validColumnRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    return validColumnRegex.hasMatch(column);
  }

  /// Validates SQL operator
  bool _isValidOperator(String operator) {
    const validOperators = [
      '=',
      '!=',
      '<>',
      '<',
      '>',
      '<=',
      '>=',
      'LIKE',
      'NOT LIKE',
      'IN',
      'NOT IN',
      'IS NULL',
      'IS NOT NULL',
    ];
    return validOperators.contains(operator.toUpperCase());
  }
}

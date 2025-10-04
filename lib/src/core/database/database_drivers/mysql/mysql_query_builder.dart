import 'dart:async';

import '../../../../contracts/database/connection_interface.dart';
import '../../../../contracts/database/query_builder_interface.dart';
import '../../../../support/exceptions/database_exception.dart';
import '../../model_base/khadem_model.dart';
import '../../orm/paginated_result.dart';
import 'eager_loader.dart';

/// A fluent and type-safe MySQL query builder for both Maps and BaseModel subclasses.
///
/// Supports common SQL operations like select, where, insert, update, delete,
/// and type-safe transformation using a model factory.
class MySQLQueryBuilder<T> implements QueryBuilderInterface<T> {
  final ConnectionInterface _connection;
  final String _table;
  final T Function(Map<String, dynamic>)? _modelFactory;

  List<String> _columns = ['*'];
  final List<String> _where = [];
  List<dynamic> _eagerRelations = [];
  bool _isDistinct = false;

  final List<dynamic> _bindings = [];
  int? _limit;
  int? _offset;
  String? _orderBy;
  String? _groupBy;
  String? _having;

  MySQLQueryBuilder(
    this._connection,
    this._table, {
    T Function(Map<String, dynamic>)? modelFactory,
  }) : _modelFactory = modelFactory;

  @override
  QueryBuilderInterface<T> select(List<String> columns) {
    _columns = columns;
    return this;
  }

  @override
  QueryBuilderInterface<T> where(
    String column,
    String operator,
    dynamic value,
  ) {
    _where.add('`$column` $operator ?');
    _bindings.add(value);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereRaw(String sql, [List bindings = const []]) {
    _where.add(sql);
    _bindings.addAll(bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhere(
    String column,
    String operator,
    dynamic value,
  ) {
    if (_where.isEmpty) return where(column, operator, value);
    _where.add('OR `$column` $operator ?');
    _bindings.add(value);
    return this;
  }

  // ---------------------------- Advanced WHERE Clauses ----------------------------

  @override
  QueryBuilderInterface<T> whereIn(String column, List<dynamic> values) {
    if (values.isEmpty) return this;

    final placeholders = List.filled(values.length, '?').join(', ');
    _where.add('`$column` IN ($placeholders)');
    _bindings.addAll(values);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotIn(String column, List<dynamic> values) {
    if (values.isEmpty) return this;

    final placeholders = List.filled(values.length, '?').join(', ');
    _where.add('`$column` NOT IN ($placeholders)');
    _bindings.addAll(values);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNull(String column) {
    _where.add('`$column` IS NULL');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotNull(String column) {
    _where.add('`$column` IS NOT NULL');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereBetween(
    String column,
    dynamic start,
    dynamic end,
  ) {
    _where.add('`$column` BETWEEN ? AND ?');
    _bindings.addAll([start, end]);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotBetween(
    String column,
    dynamic start,
    dynamic end,
  ) {
    _where.add('`$column` NOT BETWEEN ? AND ?');
    _bindings.addAll([start, end]);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereLike(String column, String pattern) {
    _where.add('`$column` LIKE ?');
    _bindings.add(pattern);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotLike(String column, String pattern) {
    _where.add('`$column` NOT LIKE ?');
    _bindings.add(pattern);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereDate(String column, String date) {
    _where.add('DATE(`$column`) = ?');
    _bindings.add(date);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereTime(String column, String time) {
    _where.add('TIME(`$column`) = ?');
    _bindings.add(time);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereYear(String column, int year) {
    _where.add('YEAR(`$column`) = ?');
    _bindings.add(year);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereMonth(String column, int month) {
    _where.add('MONTH(`$column`) = ?');
    _bindings.add(month);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereDay(String column, int day) {
    _where.add('DAY(`$column`) = ?');
    _bindings.add(day);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereColumn(
    String column1,
    String operator,
    String column2,
  ) {
    _where.add('`$column1` $operator `$column2`');
    return this;
  }

  // ---------------------------- JSON Operations ----------------------------

  @override
  QueryBuilderInterface<T> whereJsonContains(
    String column,
    dynamic value, [
    String? path,
  ]) {
    final jsonValue = value is String ? '"$value"' : _jsonEncode(value);
    if (path != null) {
      _where.add('JSON_CONTAINS(`$column`, ?, ?)');
      _bindings.addAll([jsonValue, '\$.$path']);
    } else {
      _where.add('JSON_CONTAINS(`$column`, ?)');
      _bindings.add(jsonValue);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonDoesntContain(
    String column,
    dynamic value, [
    String? path,
  ]) {
    final jsonValue = value is String ? '"$value"' : _jsonEncode(value);
    if (path != null) {
      _where.add('NOT JSON_CONTAINS(`$column`, ?, ?)');
      _bindings.addAll([jsonValue, '\$.$path']);
    } else {
      _where.add('NOT JSON_CONTAINS(`$column`, ?)');
      _bindings.add(jsonValue);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonLength(
    String column,
    String operator,
    int length, [
    String? path,
  ]) {
    if (path != null) {
      _where.add('JSON_LENGTH(`$column`, ?) $operator ?');
      _bindings.addAll(['\$.$path', length]);
    } else {
      _where.add('JSON_LENGTH(`$column`) $operator ?');
      _bindings.add(length);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonContainsKey(String column, String path) {
    _where.add("JSON_CONTAINS_PATH(`$column`, 'one', ?)");
    _bindings.add('\$.$path');
    return this;
  }

  // ---------------------------- Advanced Query Helpers ----------------------------

  @override
  QueryBuilderInterface<T> whereAny(
    List<String> columns,
    String operator,
    dynamic value,
  ) {
    if (columns.isEmpty) return this;

    final conditions = columns.map((col) => '`$col` $operator ?').join(' OR ');
    _where.add('($conditions)');
    for (int i = 0; i < columns.length; i++) {
      _bindings.add(value);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> whereAll(Map<String, dynamic> conditions) {
    conditions.forEach((column, value) {
      where(column, '=', value);
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNone(Map<String, dynamic> conditions) {
    if (conditions.isEmpty) return this;

    final conditionsList =
        conditions.entries.map((e) => '`${e.key}` = ?').join(' OR ');
    _where.add('NOT ($conditionsList)');
    _bindings.addAll(conditions.values);
    return this;
  }

  @override
  QueryBuilderInterface<T> latest([String column = 'created_at']) {
    return orderBy(column, direction: 'DESC');
  }

  @override
  QueryBuilderInterface<T> oldest([String column = 'created_at']) {
    return orderBy(column, direction: 'ASC');
  }

  @override
  QueryBuilderInterface<T> inRandomOrder() {
    _orderBy = 'RAND()';
    return this;
  }

  @override
  QueryBuilderInterface<T> distinct() {
    // Store distinct flag - will be used in _buildSelectQuery
    _isDistinct = true;
    return this;
  }

  @override
  QueryBuilderInterface<T> addSelect(List<String> columns) {
    if (_columns.contains('*')) {
      _columns = columns;
    } else {
      _columns.addAll(columns);
    }
    return this;
  }

  /// Helper method to encode JSON values
  String _jsonEncode(dynamic value) {
    if (value is Map || value is List) {
      return value.toString().replaceAll("'", '"');
    }
    return value.toString();
  }

  @override
  QueryBuilderInterface<T> limit(int number) {
    _limit = number;
    return this;
  }

  @override
  QueryBuilderInterface<T> offset(int number) {
    _offset = number;
    return this;
  }

  @override
  QueryBuilderInterface<T> orderBy(String column, {String direction = 'ASC'}) {
    _orderBy = '`$column` ${direction.toUpperCase()}';
    return this;
  }

  @override
  QueryBuilderInterface<T> groupBy(String column) {
    _groupBy = '`$column`';
    return this;
  }

  /// Fetches all results matching the query and converts to type `T`.
  @override
  Future<List<T>> get() async {
    final sql = _buildSelectQuery();
    final rawResults = await _connection.execute(sql, _bindings);

    if (T == Map || _modelFactory == null) {
      return List<T>.from(rawResults.data);
    }
    final models =
        List<T>.from(rawResults.data.map((e) => _modelFactory?.call(e)));
    if (_eagerRelations.isNotEmpty) {
      await _eagerLoadRelations(models);
    }

    return models;
  }

  Future<void> _eagerLoadRelations(List<T> models) async {
    await EagerLoader.loadRelations(
      models.cast<KhademModel>(),
      _eagerRelations,
    );
  }

  /// Fetches the first matching result and converts to type `T`.
  @override
  Future<T?> first() async {
    limit(1);
    final results = await get();
    return results.isEmpty ? null : results.first;
  }

  /// Inserts a record into the table.
  @override
  Future<int> insert(Map<String, dynamic> data) async {
    final columns = data.keys.map((k) => '`$k`').join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');
    final values = data.values.toList();
    final sql = 'INSERT INTO `$_table` ($columns) VALUES ($placeholders)';
    final result = await _connection.execute(sql, values);
    return result.insertId ?? -1;
  }

  /// Updates records matching the WHERE clause.
  @override
  Future<void> update(Map<String, dynamic> data) async {
    if (_where.isEmpty) {
      throw DatabaseException('Update without WHERE clause is not allowed.');
    }

    final setClause = data.keys.map((k) => '`$k` = ?').join(', ');
    final values = [...data.values, ..._bindings];
    final sql = 'UPDATE `$_table` SET $setClause WHERE ${_where.join(' AND ')}';
    await _connection.execute(sql, values);
  }

  /// Deletes records matching the WHERE clause.
  @override
  Future<void> delete() async {
    if (_where.isEmpty) {
      throw DatabaseException('Delete without WHERE clause is not allowed.');
    }

    final sql = 'DELETE FROM `$_table` WHERE ${_where.join(' AND ')}';
    await _connection.execute(sql, _bindings);
  }

  /// Fetches a paginated list of results.
  @override
  Future<PaginatedResult<T>> paginate({
    int? perPage = 10,
    int? page = 1,
  }) async {
    perPage ??= 10;
    page ??= 1;

    final countQuery = clone();
    final totalCount = await countQuery.count();

    final offsetValue = (page - 1) * perPage;
    limit(perPage);
    offset(offsetValue);
    final items = await get();

    return PaginatedResult<T>(
      data: items,
      total: totalCount,
      perPage: perPage,
      currentPage: page,
      lastPage: (totalCount / perPage).ceil(),
    );
  }

  /// Returns the count of records matching the query.
  @override
  Future<int> count() async {
    _columns = ['COUNT(*) as count'];
    final result = await first();
    return result is Map<String, dynamic>
        ? result['count'] as int
        : result is KhademModel
            ? result.rawData['count'] as int
            : 0;
  }

  /// Returns a stream of results for memory-efficient processing of large datasets.
  ///
  /// This method is particularly useful when combined with response.stream()
  /// for sending large amounts of data without loading everything into memory.
  ///
  /// Example:
  /// ```dart
  /// server.get('/api/export/users', (req, res) async {
  ///   res.header('Content-Type', 'application/json');
  ///   final userStream = User.query().asStream()
  ///     .map((user) => jsonEncode(user.toJson()) + '\\n');
  ///   await res.stream(userStream);
  /// });
  /// ```
  @override
  Stream<T> asStream() {
    final sql = _buildSelectQuery();
    final streamController = StreamController<T>();

    // Execute query and stream results
    _connection.execute(sql, _bindings).then((result) {
      for (final row in result.data) {
        if (T == Map || _modelFactory == null) {
          streamController.add(row as T);
        } else {
          final model = _modelFactory?.call(row);
          if (model != null) {
            streamController.add(model);
          }
        }
      }
      streamController.close();
    }).catchError((error) {
      streamController.addError(error);
      streamController.close();
    });

    return streamController.stream;
  }

  /// Returns true if any record matches the query.
  @override
  Future<bool> exists() async {
    limit(1);
    final result = await get();
    return result.isNotEmpty;
  }

  /// Returns the value of a single column.
  @override
  Future<List<dynamic>> pluck(String column) async {
    select([column]);
    final results = await _connection.execute(_buildSelectQuery(), _bindings);
    return results.data.map((e) => e[column]).toList();
  }

  /// Builds the SELECT query string based on current state.
  String _buildSelectQuery() {
    final distinct = _isDistinct ? 'DISTINCT ' : '';
    final buffer =
        StringBuffer('SELECT $distinct${_columns.join(', ')} FROM `$_table`');

    if (_where.isNotEmpty) buffer.write(' WHERE ${_where.join(' AND ')}');
    if (_groupBy != null) buffer.write(' GROUP BY $_groupBy');
    if (_having != null) buffer.write(' HAVING $_having');
    if (_orderBy != null) buffer.write(' ORDER BY $_orderBy');
    if (_limit != null) buffer.write(' LIMIT $_limit');
    if (_offset != null) buffer.write(' OFFSET $_offset');

    return buffer.toString();
  }

  /// Adds a HAVING clause (used with GROUP BY).
  @override
  QueryBuilderInterface<T> having(
    String column,
    String operator,
    dynamic value,
  ) {
    _having = '`$column` $operator "$value"';
    return this;
  }

  /// Returns the raw SQL query as a string.
  @override
  String toSql() {
    return _buildSelectQuery();
  }

  /// Conditionally modifies the query based on a boolean.
  ///
  /// Example:
  /// ```dart
  /// query.when(isAdmin, (q) => q.where('role', '=', 'admin'));
  /// ```
  @override
  QueryBuilderInterface<T> when(
    bool condition,
    QueryBuilderInterface<T> Function(QueryBuilderInterface<T> q) builder,
  ) {
    return condition ? builder(this) : this;
  }

  /// Returns the sum of a numeric column.
  @override
  Future<num> sum(String column) async {
    _columns = ['SUM(`$column`) as total'];
    final result = await first();
    return (result as Map<String, dynamic>)['total'] ?? 0;
  }

  /// Returns the average of a numeric column.
  @override
  Future<num> avg(String column) async {
    _columns = ['AVG(`$column`) as avg'];
    final result = await first();
    return (result as Map<String, dynamic>)['avg'] ?? 0;
  }

  /// Returns the maximum value of a numeric column.
  @override
  Future<int> max(String column) async {
    _columns = ['MAX(`$column`) as max'];
    final result = await first();
    return (result as Map<String, dynamic>)['max'] as int;
  }

  /// Returns the minimum value of a numeric column.
  @override
  Future<int> min(String column) async {
    _columns = ['MIN(`$column`) as min'];
    final result = await first();
    return (result as Map<String, dynamic>)['min'] as int;
  }

  /// Adds relations with optional query constraints
  ///
  /// Example:
  /// ```dart
  /// .withRelations([
  ///   'posts',
  ///   {
  ///     'comments': {
  ///       'query': (query) => query.where('approved', true),
  ///       'with': ['user']
  ///     }
  ///   }
  /// ])
  /// ```
  @override
  QueryBuilderInterface<T> withRelations(List<dynamic> relations) {
    _eagerRelations = relations;
    return this;
  }

  @override
  QueryBuilderInterface<T> clone() {
    final cloned =
        MySQLQueryBuilder<T>(_connection, _table, modelFactory: _modelFactory);
    cloned._columns = [..._columns];
    cloned._where.addAll(_where);
    cloned._bindings.addAll(_bindings);
    cloned._eagerRelations = [..._eagerRelations];
    cloned._isDistinct = _isDistinct;
    cloned._limit = _limit;
    cloned._offset = _offset;
    cloned._orderBy = _orderBy;
    cloned._groupBy = _groupBy;
    cloned._having = _having;
    return cloned;
  }
}

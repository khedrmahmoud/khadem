import 'dart:async';

import '../../../../contracts/database/connection_interface.dart';
import '../../../../contracts/database/query_builder_interface.dart';
import '../../../../support/exceptions/database_exception.dart';
import '../../model_base/khadem_model.dart';
import '../../orm/paginated_result.dart';
import '../../orm/relation_definition.dart';
import '../../orm/relation_type.dart';
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
  List<String> _excludedRelations = [];  // Relations to exclude from defaultRelations
  bool _useOnlyRelations = false;        // If true, ignore defaultRelations
  bool _isDistinct = false;
  final List<String> _joins = [];
  final List<String> _unions = [];
  String? _lock;

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

  // ---------------------------- JOIN Operations ----------------------------

  @override
  QueryBuilderInterface<T> join(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  ) {
    _joins.add('INNER JOIN `$table` ON `$firstColumn` $operator `$secondColumn`');
    return this;
  }

  @override
  QueryBuilderInterface<T> leftJoin(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  ) {
    _joins.add('LEFT JOIN `$table` ON `$firstColumn` $operator `$secondColumn`');
    return this;
  }

  @override
  QueryBuilderInterface<T> rightJoin(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  ) {
    _joins.add('RIGHT JOIN `$table` ON `$firstColumn` $operator `$secondColumn`');
    return this;
  }

  @override
  QueryBuilderInterface<T> crossJoin(String table) {
    _joins.add('CROSS JOIN `$table`');
    return this;
  }

  // ---------------------------- Bulk Operations ----------------------------

  @override
  Future<List<int>> insertMany(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return [];

    final columns = rows.first.keys.map((k) => '`$k`').join(', ');
    final placeholders = rows.map((row) {
      return '(${List.filled(row.length, '?').join(', ')})';
    }).join(', ');

    final values = rows.expand((row) => row.values).toList();

    final sql = 'INSERT INTO `$_table` ($columns) VALUES $placeholders';
    final result = await _connection.execute(sql, values);

    // Return list of inserted IDs
    final firstId = result.insertId ?? 0;
    return List.generate(rows.length, (i) => firstId + i);
  }

  @override
  Future<int> upsert(
    List<Map<String, dynamic>> rows, {
    required List<String> uniqueBy,
    List<String>? update,
  }) async {
    if (rows.isEmpty) return 0;

    final columns = rows.first.keys.map((k) => '`$k`').join(', ');
    final placeholders = rows.map((row) {
      return '(${List.filled(row.length, '?').join(', ')})';
    }).join(', ');

    final values = rows.expand((row) => row.values).toList();

    // Determine which columns to update
    final updateColumns = update ?? rows.first.keys.toList();
    final updateClause = updateColumns
        .where((col) => !uniqueBy.contains(col))
        .map((col) => '`$col` = VALUES(`$col`)')
        .join(', ');

    final sql = '''
      INSERT INTO `$_table` ($columns) 
      VALUES $placeholders
      ON DUPLICATE KEY UPDATE $updateClause
    ''';

    final result = await _connection.execute(sql, values);
    return result.affectedRows ?? 0;
  }

  @override
  Future<int> increment(String column, [int amount = 1]) async {
    if (_where.isEmpty) {
      throw DatabaseException('Increment without WHERE clause is not allowed.');
    }

    final sql =
        'UPDATE `$_table` SET `$column` = `$column` + ? WHERE ${_where.join(' AND ')}';
    final result = await _connection.execute(sql, [amount, ..._bindings]);
    return result.affectedRows ?? 0;
  }

  @override
  Future<int> decrement(String column, [int amount = 1]) async {
    if (_where.isEmpty) {
      throw DatabaseException('Decrement without WHERE clause is not allowed.');
    }

    final sql =
        'UPDATE `$_table` SET `$column` = `$column` - ? WHERE ${_where.join(' AND ')}';
    final result = await _connection.execute(sql, [amount, ..._bindings]);
    return result.affectedRows ?? 0;
  }

  @override
  Future<void> incrementEach(Map<String, int> columns) async {
    if (_where.isEmpty) {
      throw DatabaseException(
        'IncrementEach without WHERE clause is not allowed.',
      );
    }

    final setClause = columns.entries
        .map((e) => '`${e.key}` = `${e.key}` + ?')
        .join(', ');
    final values = [...columns.values, ..._bindings];

    final sql =
        'UPDATE `$_table` SET $setClause WHERE ${_where.join(' AND ')}';
    await _connection.execute(sql, values);
  }

  @override
  Future<void> chunk(
    int size,
    Future<void> Function(List<T> items) callback,
  ) async {
    int page = 1;
    List<T> items;

    do {
      final query = clone();
      items = await query.offset((page - 1) * size).limit(size).get();

      if (items.isNotEmpty) {
        await callback(items);
      }

      page++;
    } while (items.length == size);
  }

  @override
  Future<void> chunkById(
    int size,
    Future<void> Function(List<T> items) callback, {
    String column = 'id',
    String? alias,
  }) async {
    final columnName = alias ?? column;
    dynamic lastId;

    do {
      final query = clone();

      if (lastId != null) {
        query.where(column, '>', lastId);
      }

      final items = await query.orderBy(column).limit(size).get();

      if (items.isEmpty) break;

      await callback(items);

      // Get the last ID from the chunk
      final lastItem = items.last;
      if (lastItem is Map<String, dynamic>) {
        lastId = lastItem[columnName];
      } else if (lastItem is KhademModel) {
        lastId = lastItem.rawData[columnName];
      }
    } while (true);
  }

  @override
  Stream<T> lazy([int chunkSize = 100]) async* {
    int page = 1;
    List<T> items;

    do {
      final query = clone();
      items = await query.offset((page - 1) * chunkSize).limit(chunkSize).get();

      for (final item in items) {
        yield item;
      }

      page++;
    } while (items.length == chunkSize);
  }

  // ---------------------------- Advanced Pagination & Locking ----------------------------

  @override
  Future<Map<String, dynamic>> simplePaginate({
    int perPage = 15,
    int page = 1,
  }) async {
    // Get one extra item to check if there are more pages
    final query = clone();
    final items = await query
        .offset((page - 1) * perPage)
        .limit(perPage + 1)
        .get();

    final hasMorePages = items.length > perPage;
    final data = hasMorePages ? items.sublist(0, perPage) : items;

    return {
      'data': data,
      'perPage': perPage,
      'currentPage': page,
      'hasMorePages': hasMorePages,
      'from': (page - 1) * perPage + 1,
      'to': (page - 1) * perPage + data.length,
    };
  }

  @override
  Future<Map<String, dynamic>> cursorPaginate({
    int perPage = 15,
    String? cursor,
    String column = 'id',
  }) async {
    final query = clone();

    // If cursor is provided, add WHERE condition
    if (cursor != null) {
      query.where(column, '>', cursor);
    }

    // Get one extra item to check if there are more pages
    final items = await query.orderBy(column).limit(perPage + 1).get();

    final hasMore = items.length > perPage;
    final data = hasMore ? items.sublist(0, perPage) : items;

    // Get next cursor
    String? nextCursor;
    if (hasMore && data.isNotEmpty) {
      final lastItem = data.last;
      if (lastItem is Map<String, dynamic>) {
        nextCursor = lastItem[column]?.toString();
      } else if (lastItem is KhademModel) {
        nextCursor = lastItem.rawData[column]?.toString();
      }
    }

    return {
      'data': data,
      'perPage': perPage,
      'nextCursor': nextCursor,
      'previousCursor': cursor,
      'hasMore': hasMore,
    };
  }

  @override
  QueryBuilderInterface<T> sharedLock() {
    _lock = 'FOR SHARE';
    return this;
  }

  @override
  QueryBuilderInterface<T> lockForUpdate() {
    _lock = 'FOR UPDATE';
    return this;
  }

  // ---------------------------- Union & Subqueries ----------------------------

  @override
  QueryBuilderInterface<T> union(QueryBuilderInterface<T> query) {
    _unions.add('UNION (${query.toSql()})');
    return this;
  }

  @override
  QueryBuilderInterface<T> unionAll(QueryBuilderInterface<T> query) {
    _unions.add('UNION ALL (${query.toSql()})');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereInSubquery(
    String column,
    String Function(QueryBuilderInterface<dynamic> query) callback,
  ) {
    final subquery = MySQLQueryBuilder<Map<String, dynamic>>(_connection, _table);
    final subquerySql = callback(subquery);
    _where.add('`$column` IN ($subquerySql)');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereExists(
    String Function(QueryBuilderInterface<dynamic> query) callback,
  ) {
    final subquery = MySQLQueryBuilder<Map<String, dynamic>>(_connection, _table);
    final subquerySql = callback(subquery);
    _where.add('EXISTS ($subquerySql)');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotExists(
    String Function(QueryBuilderInterface<dynamic> query) callback,
  ) {
    final subquery = MySQLQueryBuilder<Map<String, dynamic>>(_connection, _table);
    final subquerySql = callback(subquery);
    _where.add('NOT EXISTS ($subquerySql)');
    return this;
  }

  // ---------------------------- Full-Text Search ----------------------------

  @override
  QueryBuilderInterface<T> whereFullText(
    List<String> columns,
    String searchTerm, {
    String mode = 'natural',
  }) {
    final columnList = columns.map((c) => '`$c`').join(', ');

    String matchMode;
    switch (mode) {
      case 'boolean':
        matchMode = 'IN BOOLEAN MODE';
        break;
      case 'query_expansion':
        matchMode = 'WITH QUERY EXPANSION';
        break;
      default:
        matchMode = 'IN NATURAL LANGUAGE MODE';
    }

    _where.add('MATCH ($columnList) AGAINST (? $matchMode)');
    _bindings.add(searchTerm);
    return this;
  }

  // ---------------------------- OR WHERE Variants ----------------------------

  @override
  QueryBuilderInterface<T> orWhereIn(String column, List<dynamic> values) {
    if (values.isEmpty) return this;
    if (_where.isEmpty) return whereIn(column, values);

    final placeholders = List.filled(values.length, '?').join(', ');
    _where.add('OR `$column` IN ($placeholders)');
    _bindings.addAll(values);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotIn(String column, List<dynamic> values) {
    if (values.isEmpty) return this;
    if (_where.isEmpty) return whereNotIn(column, values);

    final placeholders = List.filled(values.length, '?').join(', ');
    _where.add('OR `$column` NOT IN ($placeholders)');
    _bindings.addAll(values);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNull(String column) {
    if (_where.isEmpty) return whereNull(column);
    _where.add('OR `$column` IS NULL');
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotNull(String column) {
    if (_where.isEmpty) return whereNotNull(column);
    _where.add('OR `$column` IS NOT NULL');
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereBetween(
    String column,
    dynamic start,
    dynamic end,
  ) {
    if (_where.isEmpty) return whereBetween(column, start, end);
    _where.add('OR `$column` BETWEEN ? AND ?');
    _bindings.addAll([start, end]);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotBetween(
    String column,
    dynamic start,
    dynamic end,
  ) {
    if (_where.isEmpty) return whereNotBetween(column, start, end);
    _where.add('OR `$column` NOT BETWEEN ? AND ?');
    _bindings.addAll([start, end]);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereLike(String column, String pattern) {
    if (_where.isEmpty) return whereLike(column, pattern);
    _where.add('OR `$column` LIKE ?');
    _bindings.add(pattern);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotLike(String column, String pattern) {
    if (_where.isEmpty) return whereNotLike(column, pattern);
    _where.add('OR `$column` NOT LIKE ?');
    _bindings.add(pattern);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereDate(String column, String date) {
    if (_where.isEmpty) return whereDate(column, date);
    _where.add('OR DATE(`$column`) = ?');
    _bindings.add(date);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereTime(String column, String time) {
    if (_where.isEmpty) return whereTime(column, time);
    _where.add('OR TIME(`$column`) = ?');
    _bindings.add(time);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereYear(String column, int year) {
    if (_where.isEmpty) return whereYear(column, year);
    _where.add('OR YEAR(`$column`) = ?');
    _bindings.add(year);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereMonth(String column, int month) {
    if (_where.isEmpty) return whereMonth(column, month);
    _where.add('OR MONTH(`$column`) = ?');
    _bindings.add(month);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereDay(String column, int day) {
    if (_where.isEmpty) return whereDay(column, day);
    _where.add('OR DAY(`$column`) = ?');
    _bindings.add(day);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereColumn(
    String column1,
    String operator,
    String column2,
  ) {
    if (_where.isEmpty) return whereColumn(column1, operator, column2);
    _where.add('OR `$column1` $operator `$column2`');
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereJsonContains(
    String column,
    dynamic value, [
    String? path,
  ]) {
    if (_where.isEmpty) return whereJsonContains(column, value, path);

    final jsonValue = value is String ? '"$value"' : _jsonEncode(value);
    if (path != null) {
      _where.add('OR JSON_CONTAINS(`$column`, ?, ?)');
      _bindings.addAll([jsonValue, '\$.$path']);
    } else {
      _where.add('OR JSON_CONTAINS(`$column`, ?)');
      _bindings.add(jsonValue);
    }
    return this;
  }

  // ---------------------------- Relationship Queries (whereHas) ----------------------------

  @override
  QueryBuilderInterface<T> whereHas(
    String relation, [
    void Function(QueryBuilderInterface<dynamic> query)? callback,
    String operator = '>=',
    int count = 1,
  ]) {
    // Check if this is a nested relation (e.g., 'chat_room_users.user')
    if (relation.contains('.')) {
      return _whereHasNested(relation, callback, operator, count);
    }
    
    // Build subquery that counts related records
    final relatedTable = _getRelationTable(relation);
    final foreignKey = _getRelationForeignKey(relation);
    final subquery = MySQLQueryBuilder<Map<String, dynamic>>(_connection, relatedTable);
    
    // Apply user constraints
    if (callback != null) {
      callback(subquery);
    }
    
    // Build correlated subquery with proper parent table reference
    // The foreign key in the related table should equal the id in the parent table
    final whereConditions = <String>[];
    
    // Add the correlation condition (link to parent table)
    whereConditions.add('`$relatedTable`.`$foreignKey` = `$_table`.`id`');
    
    // Add user-defined where conditions from the subquery
    if (subquery._where.isNotEmpty) {
      for (var i = 0; i < subquery._where.length; i++) {
        var condition = subquery._where[i];
        // Remove AND/OR prefixes as we're building a fresh list
        condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
        whereConditions.add(condition);
      }
    }
    
    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';
    final countSql = 'SELECT COUNT(*) FROM `$relatedTable` $whereClause';
    
    _where.add('($countSql) $operator ?');
    _bindings.addAll(subquery._bindings);
    _bindings.add(count);
    
    return this;
  }

  /// Handle nested relations in whereHas (e.g., 'posts.comments.user')
  QueryBuilderInterface<T> _whereHasNested(
    String relation,
    void Function(QueryBuilderInterface<dynamic> query)? callback,
    String operator,
    int count,
  ) {
    final parts = relation.split('.');
    
    // Build the nested subquery manually by traversing the relation chain
    return _buildNestedWhereHas(parts, callback, operator, count, false);
  }

  /// Recursively build nested whereHas subqueries
  QueryBuilderInterface<T> _buildNestedWhereHas(
    List<String> relationParts,
    void Function(QueryBuilderInterface<dynamic> query)? callback,
    String operator,
    int count,
    bool isOr,
  ) {
    if (relationParts.isEmpty) return this;
    
    final currentRelation = relationParts[0];
    final remainingParts = relationParts.sublist(1);
    
    if (remainingParts.isEmpty) {
      // This is the last relation, apply the callback here
      if (isOr) {
        return orWhereHas(currentRelation, callback, operator, count);
      } else {
        return whereHas(currentRelation, callback, operator, count);
      }
    } else {
      // More relations to traverse, nest deeper
      // Get the next relation info from the current model
      final relatedModelFactory = _getRelatedModelFactory(currentRelation);
      
      if (isOr) {
        return orWhereHas(currentRelation, (subQuery) {
          if (subQuery is MySQLQueryBuilder && relatedModelFactory != null) {
            // Get the next relation definition
            final nextRelation = remainingParts[0];
            final nextRelationDef = _getRelationDefinitionFromFactory(relatedModelFactory, nextRelation);
            
            if (nextRelationDef == null) {
              print('Warning: Could not find relation definition for $nextRelation');
              return;
            }
            
            if (remainingParts.length == 1) {
              // This is the last nested level, apply the callback
              final nestedQuery = MySQLQueryBuilder<Map<String, dynamic>>(
                subQuery._connection,
                nextRelationDef.relatedTable,
              );
              
              if (callback != null) {
                callback(nestedQuery);
              }
              
              // Build the correlation condition based on relation type
              final whereConditions = <String>[];
              final correlationCondition = _buildCorrelationCondition(
                subQuery._table,
                nextRelationDef,
              );
              whereConditions.add(correlationCondition);
              
              if (nestedQuery._where.isNotEmpty) {
                for (var i = 0; i < nestedQuery._where.length; i++) {
                  var condition = nestedQuery._where[i];
                  condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
                  whereConditions.add(condition);
                }
              }
              
              final whereClause = whereConditions.isNotEmpty
                  ? 'WHERE ${whereConditions.join(' AND ')}'
                  : '';
              final countSql = 'SELECT COUNT(*) FROM `${nextRelationDef.relatedTable}` $whereClause';
              
              subQuery._where.add('($countSql) $operator ?');
              subQuery._bindings.addAll(nestedQuery._bindings);
              subQuery._bindings.add(count);
            } else {
              // More nesting needed - recursive call with the related model factory
              final nextRelatedModelFactory = nextRelationDef.factory().newFactory;
              final nestedBuilder = MySQLQueryBuilder(
                subQuery._connection,
                nextRelationDef.relatedTable,
                modelFactory: nextRelatedModelFactory,
              );
              
              nestedBuilder._buildNestedWhereHas(
                remainingParts,
                callback,
                operator,
                count,
                false,
              );
              
              // Copy the conditions
              if (nestedBuilder._where.isNotEmpty) {
                subQuery._where.addAll(nestedBuilder._where);
                subQuery._bindings.addAll(nestedBuilder._bindings);
              }
            }
          }
        });
      } else {
        return whereHas(currentRelation, (subQuery) {
          if (subQuery is MySQLQueryBuilder && relatedModelFactory != null) {
            // Get the next relation definition
            final nextRelation = remainingParts[0];
            final nextRelationDef = _getRelationDefinitionFromFactory(relatedModelFactory, nextRelation);
            
            if (nextRelationDef == null) {
              print('Warning: Could not find relation definition for $nextRelation');
              return;
            }
            
            if (remainingParts.length == 1) {
              // This is the last nested level, apply the callback
              final nestedQuery = MySQLQueryBuilder<Map<String, dynamic>>(
                subQuery._connection,
                nextRelationDef.relatedTable,
              );
              
              if (callback != null) {
                callback(nestedQuery);
              }
              
              // Build the correlation condition based on relation type
              final whereConditions = <String>[];
              final correlationCondition = _buildCorrelationCondition(
                subQuery._table,
                nextRelationDef,
              );
              whereConditions.add(correlationCondition);
              
              if (nestedQuery._where.isNotEmpty) {
                for (var i = 0; i < nestedQuery._where.length; i++) {
                  var condition = nestedQuery._where[i];
                  condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
                  whereConditions.add(condition);
                }
              }
              
              final whereClause = whereConditions.isNotEmpty
                  ? 'WHERE ${whereConditions.join(' AND ')}'
                  : '';
              final countSql = 'SELECT COUNT(*) FROM `${nextRelationDef.relatedTable}` $whereClause';
              
              subQuery._where.add('($countSql) $operator ?');
              subQuery._bindings.addAll(nestedQuery._bindings);
              subQuery._bindings.add(count);
            } else {
              // More nesting needed - recursive call with the related model factory
              final nextRelatedModelFactory = nextRelationDef.factory().newFactory;
              final nestedBuilder = MySQLQueryBuilder(
                subQuery._connection,
                nextRelationDef.relatedTable,
                modelFactory: nextRelatedModelFactory,
              );
              
              nestedBuilder._buildNestedWhereHas(
                remainingParts,
                callback,
                operator,
                count,
                false,
              );
              
              // Copy the conditions
              if (nestedBuilder._where.isNotEmpty) {
                subQuery._where.addAll(nestedBuilder._where);
                subQuery._bindings.addAll(nestedBuilder._bindings);
              }
            }
          }
        });
      }
    }
  }

  /// Get full relation definition from a model factory
  RelationDefinition? _getRelationDefinitionFromFactory(
    dynamic Function(Map<String, dynamic>) factory,
    String relation,
  ) {
    try {
      final tempModel = factory({});
      if (tempModel is KhademModel) {
        return tempModel.relations[relation];
      }
    } catch (e) {
      print('Error getting relation definition: $e');
    }
    return null;
  }

  /// Get the model factory for a related model
  dynamic Function(Map<String, dynamic>)? _getRelatedModelFactory(String relation) {
    if (_modelFactory == null) return null;
    
    try {
      // Create a temporary model instance to access relation definitions
      final tempModel = _modelFactory!({});
      if (tempModel is KhademModel) {
        final relationDef = tempModel.relations[relation];
        if (relationDef != null) {
          // Return a factory that creates instances of the related model
          return (data) => relationDef.factory().newFactory(data);
        }
      }
    } catch (e) {
      // Fallback if model creation fails
      print('Error getting related model factory: $e');
    }
    
    return null;
  }

  /// Build the correlation condition for a relationship based on its type
  /// 
  /// Examples:
  /// - belongsTo: `parent_table.localKey = related_table.foreignKey`
  ///   (e.g., `chat_room_users.user_id = users.id`)
  /// - hasMany/hasOne: `related_table.foreignKey = parent_table.localKey`
  ///   (e.g., `posts.user_id = users.id`)
  String _buildCorrelationCondition(
    String parentTable,
    RelationDefinition relationDef,
  ) {
    switch (relationDef.type) {
      case RelationType.belongsTo:
        // For belongsTo: parent has the foreign key
        // Example: chat_room_users.user_id = users.id
        return '`$parentTable`.`${relationDef.localKey}` = `${relationDef.relatedTable}`.`${relationDef.foreignKey}`';
      
      case RelationType.hasMany:
      case RelationType.hasOne:
        // For hasMany/hasOne: related table has the foreign key
        // Example: posts.user_id = users.id
        return '`${relationDef.relatedTable}`.`${relationDef.foreignKey}` = `$parentTable`.`${relationDef.localKey}`';
      
      case RelationType.belongsToMany:
        // For belongsToMany: need pivot table logic (not implemented in this basic version)
        throw UnimplementedError('belongsToMany in whereHas is not yet supported');
      
      case RelationType.morphOne:
      case RelationType.morphMany:
      case RelationType.morphTo:
        // For polymorphic relations: need morph type and ID fields
        throw UnimplementedError('Polymorphic relations in whereHas are not yet supported');
    }
  }

  @override
  QueryBuilderInterface<T> orWhereHas(
    String relation, [
    void Function(QueryBuilderInterface<dynamic> query)? callback,
    String operator = '>=',
    int count = 1,
  ]) {
    if (_where.isEmpty) return whereHas(relation, callback, operator, count);
    
    // Check if this is a nested relation
    if (relation.contains('.')) {
      return _orWhereHasNested(relation, callback, operator, count);
    }
    
    final relatedTable = _getRelationTable(relation);
    final foreignKey = _getRelationForeignKey(relation);
    final subquery = MySQLQueryBuilder<Map<String, dynamic>>(_connection, relatedTable);
    
    if (callback != null) {
      callback(subquery);
    }
    
    // Build correlated subquery
    final whereConditions = <String>[];
    whereConditions.add('`$relatedTable`.`$foreignKey` = `$_table`.`id`');
    
    if (subquery._where.isNotEmpty) {
      for (var i = 0; i < subquery._where.length; i++) {
        var condition = subquery._where[i];
        condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
        whereConditions.add(condition);
      }
    }
    
    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';
    final countSql = 'SELECT COUNT(*) FROM `$relatedTable` $whereClause';
    
    _where.add('OR ($countSql) $operator ?');
    _bindings.addAll(subquery._bindings);
    _bindings.add(count);
    
    return this;
  }

  /// Handle nested relations in orWhereHas
  QueryBuilderInterface<T> _orWhereHasNested(
    String relation,
    void Function(QueryBuilderInterface<dynamic> query)? callback,
    String operator,
    int count,
  ) {
    final parts = relation.split('.');
    return _buildNestedWhereHas(parts, callback, operator, count, true);
  }

  @override
  QueryBuilderInterface<T> whereDoesntHave(
    String relation, [
    void Function(QueryBuilderInterface<dynamic> query)? callback,
  ]) {
    // Check if this is a nested relation
    if (relation.contains('.')) {
      return _whereDoesntHaveNested(relation, callback);
    }
    
    final relatedTable = _getRelationTable(relation);
    final foreignKey = _getRelationForeignKey(relation);
    final subquery = MySQLQueryBuilder<Map<String, dynamic>>(_connection, relatedTable);
    
    if (callback != null) {
      callback(subquery);
    }
    
    // Build correlated subquery
    final whereConditions = <String>[];
    whereConditions.add('`$relatedTable`.`$foreignKey` = `$_table`.`id`');
    
    if (subquery._where.isNotEmpty) {
      for (var i = 0; i < subquery._where.length; i++) {
        var condition = subquery._where[i];
        condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
        whereConditions.add(condition);
      }
    }
    
    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';
    final existsSql = 'SELECT 1 FROM `$relatedTable` $whereClause LIMIT 1';
    
    _where.add('NOT EXISTS ($existsSql)');
    _bindings.addAll(subquery._bindings);
    
    return this;
  }

  /// Handle nested relations in whereDoesntHave
  QueryBuilderInterface<T> _whereDoesntHaveNested(
    String relation,
    void Function(QueryBuilderInterface<dynamic> query)? callback,
  ) {
    final parts = relation.split('.');
    return _buildNestedWhereHas(parts, callback, '>=', 1, false);
  }

  @override
  QueryBuilderInterface<T> orWhereDoesntHave(
    String relation, [
    void Function(QueryBuilderInterface<dynamic> query)? callback,
  ]) {
    if (_where.isEmpty) return whereDoesntHave(relation, callback);
    
    // Check if this is a nested relation
    if (relation.contains('.')) {
      return _orWhereDoesntHaveNested(relation, callback);
    }
    
    final relatedTable = _getRelationTable(relation);
    final foreignKey = _getRelationForeignKey(relation);
    final subquery = MySQLQueryBuilder<Map<String, dynamic>>(_connection, relatedTable);
    
    if (callback != null) {
      callback(subquery);
    }
    
    // Build correlated subquery
    final whereConditions = <String>[];
    whereConditions.add('`$relatedTable`.`$foreignKey` = `$_table`.`id`');
    
    if (subquery._where.isNotEmpty) {
      for (var i = 0; i < subquery._where.length; i++) {
        var condition = subquery._where[i];
        condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
        whereConditions.add(condition);
      }
    }
    
    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';
    final existsSql = 'SELECT 1 FROM `$relatedTable` $whereClause LIMIT 1';
    
    _where.add('OR NOT EXISTS ($existsSql)');
    _bindings.addAll(subquery._bindings);
    
    return this;
  }

  /// Handle nested relations in orWhereDoesntHave
  QueryBuilderInterface<T> _orWhereDoesntHaveNested(
    String relation,
    void Function(QueryBuilderInterface<dynamic> query)? callback,
  ) {
    final parts = relation.split('.');
    return _buildNestedWhereHas(parts, callback, '>=', 1, true);
  }

  @override
  QueryBuilderInterface<T> has(String relation, [String operator = '>=', int count = 1]) {
    return whereHas(relation, null, operator, count);
  }

  @override
  QueryBuilderInterface<T> doesntHave(String relation) {
    return whereDoesntHave(relation, null);
  }

  // Helper methods for relationship queries
  String _getRelationTable(String relation) {
    // Get the actual table name from the model's relation definition
    if (_modelFactory == null) {
      // Fallback: assume relation name matches table name
      return relation;
    }
    
    try {
      // Create a temporary model instance to access relations
      final tempModel = _modelFactory!({});
      if (tempModel is KhademModel) {
        final relationDef = tempModel.relations[relation];
        if (relationDef != null) {
          return relationDef.relatedTable;
        }
      }
    } catch (e) {
      // Fallback if model creation fails
    }
    
    // Fallback: assume relation name matches table name
    return relation;
  }

  String _getRelationForeignKey(String relation) {
    // Get the actual foreign key from the model's relation definition
    if (_modelFactory == null) {
      // Fallback: convention tablename_id
      final singularTable = _table.endsWith('s') ? _table.substring(0, _table.length - 1) : _table;
      return '${singularTable}_id';
    }
    
    try {
      // Create a temporary model instance to access relations
      final tempModel = _modelFactory!({});
      if (tempModel is KhademModel) {
        final relationDef = tempModel.relations[relation];
        if (relationDef != null) {
          return relationDef.foreignKey;
        }
      }
    } catch (e) {
      // Fallback if model creation fails
    }
    
    // Fallback: convention tablename_id
    final singularTable = _table.endsWith('s') ? _table.substring(0, _table.length - 1) : _table;
    return '${singularTable}_id';
  }

  // ---------------------------- Advanced Column Comparisons ----------------------------

  @override
  QueryBuilderInterface<T> whereBetweenColumns(
    String column,
    String startColumn,
    String endColumn,
  ) {
    _where.add('`$column` BETWEEN `$startColumn` AND `$endColumn`');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotBetweenColumns(
    String column,
    String startColumn,
    String endColumn,
  ) {
    _where.add('`$column` NOT BETWEEN `$startColumn` AND `$endColumn`');
    return this;
  }

  // ---------------------------- Advanced Date Comparisons ----------------------------

  @override
  QueryBuilderInterface<T> wherePast(String column) {
    _where.add('`$column` < NOW()');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereFuture(String column) {
    _where.add('`$column` > NOW()');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereToday(String column) {
    _where.add('DATE(`$column`) = CURDATE()');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereBeforeToday(String column) {
    _where.add('DATE(`$column`) < CURDATE()');
    return this;
  }

  @override
  QueryBuilderInterface<T> whereAfterToday(String column) {
    _where.add('DATE(`$column`) > CURDATE()');
    return this;
  }

  // ---------------------------- Subquery Methods ----------------------------

  String? _fromSubquery;
  String? _fromAlias;

  @override
  QueryBuilderInterface<T> fromSub(
    QueryBuilderInterface<dynamic> query,
    String alias,
  ) {
    if (query is MySQLQueryBuilder) {
      _fromSubquery = query._buildSelectQuery();
      _fromAlias = alias;
      _bindings.addAll(query._bindings);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> fromRaw(String sql, [List<dynamic> bindings = const []]) {
    _fromSubquery = sql;
    _bindings.addAll(bindings);
    return this;
  }

  final List<String> _selectSubqueries = [];

  @override
  QueryBuilderInterface<T> selectSub(
    QueryBuilderInterface<dynamic> query,
    String alias,
  ) {
    if (query is MySQLQueryBuilder) {
      final subquerySql = '(${query._buildSelectQuery()}) AS `$alias`';
      _selectSubqueries.add(subquerySql);
      _bindings.addAll(query._bindings);
    }
    return this;
  }

  // ---------------------------- Logical Grouping ----------------------------

  @override
  QueryBuilderInterface<T> whereNested(
    void Function(QueryBuilderInterface<T> query) callback,
  ) {
    final nestedQuery = MySQLQueryBuilder<T>(_connection, _table, modelFactory: _modelFactory);
    callback(nestedQuery);
    
    if (nestedQuery._where.isNotEmpty) {
      // Build the nested conditions properly, handling OR prefixes
      final conditions = <String>[];
      for (var i = 0; i < nestedQuery._where.length; i++) {
        var condition = nestedQuery._where[i];
        if (i == 0) {
          // First condition should not have AND/OR prefix
          condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
        } else if (!condition.startsWith('OR ') && !condition.startsWith('AND ')) {
          // If not explicitly OR/AND, default to AND
          condition = 'AND $condition';
        }
        conditions.add(condition);
      }
      final nestedConditions = conditions.join(' ');
      _where.add('($nestedConditions)');
      _bindings.addAll(nestedQuery._bindings);
    }
    
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNested(
    void Function(QueryBuilderInterface<T> query) callback,
  ) {
    if (_where.isEmpty) return whereNested(callback);
    
    final nestedQuery = MySQLQueryBuilder<T>(_connection, _table, modelFactory: _modelFactory);
    callback(nestedQuery);
    
    if (nestedQuery._where.isNotEmpty) {
      // Build the nested conditions properly, handling OR prefixes
      final conditions = <String>[];
      for (var i = 0; i < nestedQuery._where.length; i++) {
        var condition = nestedQuery._where[i];
        if (i == 0) {
          // First condition should not have AND/OR prefix
          condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
        } else if (!condition.startsWith('OR ') && !condition.startsWith('AND ')) {
          // If not explicitly OR/AND, default to AND
          condition = 'AND $condition';
        }
        conditions.add(condition);
      }
      final nestedConditions = conditions.join(' ');
      _where.add('OR ($nestedConditions)');
      _bindings.addAll(nestedQuery._bindings);
    }
    
    return this;
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
    
    // Merge defaultRelations from model with explicit eager relations
    final relationsToLoad = _getRelationsToLoad(models);
    
    if (relationsToLoad.isNotEmpty) {
      await _eagerLoadRelations(models, relationsToLoad);
    }

    // Auto-load counts from model's withCounts property
    final countsToLoad = _getCountsToLoad(models);
    if (countsToLoad.isNotEmpty) {
      // Add model's withCounts to _relationAggregates if not already there
      for (final countRelation in countsToLoad) {
        // Check if this count is not already in _relationAggregates
        final alreadyAdded = _relationAggregates.any(
          (agg) => agg['relation'] == countRelation && agg['type'] == 'count'
        );
        if (!alreadyAdded) {
          _relationAggregates.add({
            'type': 'count',
            'relation': countRelation,
            'callback': null,
          });
        }
      }
    }

    // Load relationship aggregates (withCount, withSum, etc.)
    if (_relationAggregates.isNotEmpty && models.isNotEmpty) {
      await _loadRelationAggregates(models.cast<KhademModel>());
    }

    return models;
  }

  /// Determines which relations to load based on model defaults and query settings
  List<dynamic> _getRelationsToLoad(List<T> models) {
    if (models.isEmpty) return [];
    
    // If withOnly() was called, ignore defaultRelations and use only explicit relations
    if (_useOnlyRelations) {
      return _eagerRelations;
    }
    
    // Get defaultRelations from the first model (if it's a KhademModel)
    List<dynamic> defaultRelations = [];
    if (models.first is KhademModel) {
      defaultRelations = (models.first as KhademModel).defaultRelations;
    }
    
    // Start with default relations
    final relationsToLoad = <dynamic>[...defaultRelations];
    
    // Remove excluded relations (from without() method)
    if (_excludedRelations.isNotEmpty) {
      relationsToLoad.removeWhere((relation) {
        final relationName = relation is String ? relation.split('.').first : 
                           (relation is Map ? relation.keys.first : '');
        return _excludedRelations.contains(relationName);
      });
    }
    
    // Add explicit eager relations (from withRelations() method)
    relationsToLoad.addAll(_eagerRelations);
    
    return relationsToLoad;
  }

  /// Get the list of relations to automatically count based on model's withCounts property
  List<String> _getCountsToLoad(List<T> models) {
    if (models.isEmpty) return [];
    
    // Get withCounts from the first model (if it's a KhademModel)
    if (models.first is KhademModel) {
      final withCounts = (models.first as KhademModel).withCounts;
      return List<String>.from(withCounts);
    }
    
    return [];
  }

  Future<void> _eagerLoadRelations(List<T> models, List<dynamic> relations) async {
    await EagerLoader.loadRelations(
      models.cast<KhademModel>(),
      relations,
    );
  }

  /// Load relationship aggregates (counts, sums, etc.) and add as attributes
  Future<void> _loadRelationAggregates(List<KhademModel> models) async {
    if (models.isEmpty) return;

    // Get the model's relation definitions
    final firstModel = models.first;
    final relationDefinitions = firstModel.relations;

    for (final aggregate in _relationAggregates) {
      final relationType = aggregate['type'] as String;
      final relationName = aggregate['relation'] as String;
      final column = aggregate['column'] as String?;
      final callback = aggregate['callback'] as Function?;

      // Get relation definition
      final relationDef = relationDefinitions[relationName];
      if (relationDef == null) {
        throw DatabaseException(
          'Relation "$relationName" not found on ${firstModel.runtimeType}',
        );
      }

      // Build attribute name using snake_case (e.g., "posts_count", "orders_amount_sum")
      String attributeName;
      if (relationType == 'count') {
        attributeName = '${relationName}_count';
      } else {
        attributeName = '${relationName}_${column}_${relationType}';
      }

      // Extract model IDs
      final modelIds = models.map((m) => m.id).where((id) => id != null).toList();
      if (modelIds.isEmpty) continue;

      // Build aggregate query based on relation type
      Map<int, dynamic> aggregateResults = {};

      if (relationDef.type == RelationType.hasMany || 
          relationDef.type == RelationType.hasOne) {
        // For hasMany/hasOne: SELECT foreign_key, COUNT(*) FROM related_table WHERE foreign_key IN (ids) GROUP BY foreign_key
        final selectClause = relationType == 'count'
            ? 'COUNT(*)'
            : '$relationType(`$column`)';
        
        String sql = '''
          SELECT `${relationDef.foreignKey}` as _fk, $selectClause as _aggregate
          FROM `${relationDef.relatedTable}`
          WHERE `${relationDef.foreignKey}` IN (${modelIds.map((_) => '?').join(',')})
        ''';

        // Apply callback constraints if provided
        if (callback != null) {
          final subQuery = MySQLQueryBuilder(_connection, relationDef.relatedTable);
          callback(subQuery);
          final whereClause = subQuery._where.join(' AND ');
          if (whereClause.isNotEmpty) {
            sql += ' AND $whereClause';
          }
        }

        sql += ' GROUP BY `${relationDef.foreignKey}`';

        final result = await _connection.execute(sql, modelIds);
        for (final row in result.data) {
          aggregateResults[row['_fk'] as int] = row['_aggregate'];
        }
      } 
      else if (relationDef.type == RelationType.belongsTo) {
        // For belongsTo: SELECT local_key, COUNT(*) FROM related_table WHERE local_key IN (foreign_keys) GROUP BY local_key
        final foreignKeys = models
            .map((m) => m.getField(relationDef.localKey))
            .where((fk) => fk != null)
            .toList();
        
        if (foreignKeys.isEmpty) continue;

        final selectClause = relationType == 'count'
            ? 'COUNT(*)'
            : '$relationType(`$column`)';

        String sql = '''
          SELECT `${relationDef.foreignKey}` as _fk, $selectClause as _aggregate
          FROM `${relationDef.relatedTable}`
          WHERE `${relationDef.foreignKey}` IN (${foreignKeys.map((_) => '?').join(',')})
          GROUP BY `${relationDef.foreignKey}`
        ''';

        final result = await _connection.execute(sql, foreignKeys);
        for (final row in result.data) {
          aggregateResults[row['_fk'] as int] = row['_aggregate'];
        }
      }
      else if (relationDef.type == RelationType.belongsToMany) {
        // For belongsToMany: Use pivot table
        final pivotTable = relationDef.pivotTable!;
        final foreignPivotKey = relationDef.foreignPivotKey!;
        final relatedPivotKey = relationDef.relatedPivotKey!;

        final selectClause = relationType == 'count'
            ? 'COUNT(DISTINCT pivot.`$relatedPivotKey`)'
            : '$relationType(related.`$column`)';

        String sql = '''
          SELECT pivot.`$foreignPivotKey` as _fk, $selectClause as _aggregate
          FROM `$pivotTable` pivot
          INNER JOIN `${relationDef.relatedTable}` related
            ON pivot.`$relatedPivotKey` = related.`${relationDef.foreignKey}`
          WHERE pivot.`$foreignPivotKey` IN (${modelIds.map((_) => '?').join(',')})
          GROUP BY pivot.`$foreignPivotKey`
        ''';

        final result = await _connection.execute(sql, modelIds);
        for (final row in result.data) {
          aggregateResults[row['_fk'] as int] = row['_aggregate'];
        }
      }

      // Set aggregate values on models in their relation storage
      for (final model in models) {
        final aggregateValue = aggregateResults[model.id] ?? (relationType == 'count' ? 0 : null);
        model.relation.set(attributeName, aggregateValue);
      }
    }
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
    
    // Build SELECT clause with subqueries if any
    final selectColumns = [
      ..._columns,
      ..._selectSubqueries,
    ].join(', ');
    
    // Use subquery as FROM clause if set, otherwise use table
    final fromClause = _fromSubquery != null && _fromAlias != null
      ? '($_fromSubquery) AS `$_fromAlias`'
      : (_fromSubquery ?? '`$_table`');
    
    final buffer = StringBuffer('SELECT $distinct$selectColumns FROM $fromClause');

    if (_joins.isNotEmpty) buffer.write(' ${_joins.join(' ')}');
    
    // Build WHERE clause, handling OR prefixes properly
    if (_where.isNotEmpty) {
      final whereConditions = <String>[];
      for (var i = 0; i < _where.length; i++) {
        var condition = _where[i];
        if (i == 0) {
          // First condition should not have AND/OR prefix
          condition = condition.replaceFirst(RegExp(r'^(AND |OR )'), '');
        } else if (!condition.startsWith('OR ') && !condition.startsWith('AND ')) {
          // If not explicitly OR/AND, default to AND
          condition = 'AND $condition';
        }
        whereConditions.add(condition);
      }
      buffer.write(' WHERE ${whereConditions.join(' ')}');
    }
    
    if (_groupBy != null) buffer.write(' GROUP BY $_groupBy');
    if (_having != null) buffer.write(' HAVING $_having');
    if (_orderBy != null) buffer.write(' ORDER BY $_orderBy');
    if (_limit != null) buffer.write(' LIMIT $_limit');
    if (_offset != null) buffer.write(' OFFSET $_offset');
    if (_lock != null) buffer.write(' $_lock');

    // Add unions at the end
    if (_unions.isNotEmpty) {
      buffer.write(' ${_unions.join(' ')}');
    }

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
  QueryBuilderInterface<T> without(List<String> relations) {
    _excludedRelations = relations;
    return this;
  }

  @override
  QueryBuilderInterface<T> withOnly(List<dynamic> relations) {
    _useOnlyRelations = true;
    _eagerRelations = relations;
    return this;
  }

  // ---------------------------- Relationship Aggregates ----------------------------

  /// Stores relationship aggregate queries to run
  final List<Map<String, dynamic>> _relationAggregates = [];

  @override
  QueryBuilderInterface<T> withCount(dynamic relations) {
    if (relations is String) {
      _relationAggregates.add({
        'type': 'count',
        'relation': relations,
        'callback': null,
      });
    } else if (relations is List<String>) {
      for (final relation in relations) {
        _relationAggregates.add({
          'type': 'count',
          'relation': relation,
          'callback': null,
        });
      }
    } else if (relations is Map<String, Function>) {
      for (final entry in relations.entries) {
        _relationAggregates.add({
          'type': 'count',
          'relation': entry.key,
          'callback': entry.value,
        });
      }
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> withSum(String relation, String column) {
    _relationAggregates.add({
      'type': 'sum',
      'relation': relation,
      'column': column,
      'callback': null,
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> withAvg(String relation, String column) {
    _relationAggregates.add({
      'type': 'avg',
      'relation': relation,
      'column': column,
      'callback': null,
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> withMax(String relation, String column) {
    _relationAggregates.add({
      'type': 'max',
      'relation': relation,
      'column': column,
      'callback': null,
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> withMin(String relation, String column) {
    _relationAggregates.add({
      'type': 'min',
      'relation': relation,
      'column': column,
      'callback': null,
    });
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
    cloned._excludedRelations = [..._excludedRelations];
    cloned._useOnlyRelations = _useOnlyRelations;
    cloned._isDistinct = _isDistinct;
    cloned._joins.addAll(_joins);
    cloned._unions.addAll(_unions);
    cloned._lock = _lock;
    cloned._limit = _limit;
    cloned._offset = _offset;
    cloned._orderBy = _orderBy;
    cloned._groupBy = _groupBy;
    cloned._having = _having;
    cloned._fromSubquery = _fromSubquery;
    cloned._fromAlias = _fromAlias;
    cloned._selectSubqueries.addAll(_selectSubqueries);
    return cloned;
  }
}

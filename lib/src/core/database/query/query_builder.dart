import '../../../contracts/database/database_connection.dart';
import '../../../contracts/database/query_builder_interface.dart';
import '../model_base/khadem_model.dart';
import '../orm/eager_loader.dart';
import '../orm/paginated_result.dart';
import 'grammar.dart';

/// Generic Query Builder.
class QueryBuilder<T> implements QueryBuilderInterface<T> {
  final DatabaseConnection connection;
  final Grammar grammar;
  String _table;
  @override
  String get table => _table;
  final T Function(Map<String, dynamic>)? modelFactory;

  // Query State
  List<dynamic> _columns = ['*'];
  @override
  List<dynamic> get columns => _columns;
  final List<Map<String, dynamic>> _wheres = [];
  List<Map<String, dynamic>> get wheres => _wheres;

  final List<Map<String, dynamic>> _orders = [];
  int? _limit;
  int? _offset;
  bool _distinct = false;
  String? _lock;
  final List<dynamic> _bindings = [];
  @override
  List<dynamic> get bindings => _bindings;

  final List<Map<String, dynamic>> _joins = [];
  final List<String> _groups = [];
  final List<Map<String, dynamic>> _havings = [];
  final List<Map<String, dynamic>> _unions = [];

  // Eager Loading
  final List<String> _with = [];
  final List<String> _without = [];
  final List<String> _withOnly = [];

  QueryBuilder(
    this.connection,
    this.grammar,
    String table, {
    this.modelFactory,
  }) : _table = table;

  @override
  QueryBuilderInterface<T> select(List<String> columns) {
    _columns = List<dynamic>.from(columns);
    return this;
  }

  @override
  QueryBuilderInterface<T> addSelect(List<String> columns) {
    if (_columns.length == 1 && _columns.first == '*') {
      _columns.clear();
    }
    _columns.addAll(columns);
    return this;
  }

  @override
  QueryBuilderInterface<T> selectRaw(String sql, [List bindings = const []]) {
    _columns.add({'type': 'Raw', 'sql': sql});
    _bindings.addAll(bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> where(
      String column, String operator, dynamic value,) {
    _wheres.add({
      'type': 'Basic',
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': 'AND',
    });
    _bindings.add(value);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhere(
      String column, String operator, dynamic value,) {
    _wheres.add({
      'type': 'Basic',
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': 'OR',
    });
    _bindings.add(value);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereIn(String column, List<dynamic> values) {
    _wheres.add({
      'type': 'In',
      'column': column,
      'values': values,
      'boolean': 'AND',
    });
    _bindings.addAll(values);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotIn(String column, List<dynamic> values) {
    _wheres.add({
      'type': 'NotIn',
      'column': column,
      'values': values,
      'boolean': 'AND',
    });
    _bindings.addAll(values);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNull(String column) {
    _wheres.add({
      'type': 'Null',
      'column': column,
      'boolean': 'AND',
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotNull(String column) {
    _wheres.add({
      'type': 'NotNull',
      'column': column,
      'boolean': 'AND',
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> whereRaw(String sql,
      [List bindings = const [], String boolean = 'AND',]) {
    _wheres.add({
      'type': 'Raw',
      'sql': sql,
      'boolean': boolean,
    });
    _bindings.addAll(bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereBetween(
      String column, dynamic start, dynamic end,) {
    _wheres.add({
      'type': 'Between',
      'column': column,
      'values': [start, end],
      'boolean': 'AND',
    });
    _bindings.addAll([start, end]);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotBetween(
      String column, dynamic start, dynamic end,) {
    _wheres.add({
      'type': 'NotBetween',
      'column': column,
      'values': [start, end],
      'boolean': 'AND',
    });
    _bindings.addAll([start, end]);
    return this;
  }

  @override
  QueryBuilderInterface<T> orderBy(String column, {String direction = 'ASC'}) {
    _orders.add({
      'column': column,
      'direction': direction,
    });
    return this;
  }

  // Execution Methods

  @override
  Future<List<T>> get() async {
    final sql = grammar.compileSelect(_getQueryComponents());
    final result = await connection.execute(sql, _bindings);

    List<T> items;
    if (modelFactory != null) {
      items = (result.data as List).map((row) => modelFactory!(row)).toList();
    } else {
      items = (result.data as List).cast<T>().toList();
    }

    // Eager Loading
    if (items.isNotEmpty && items.first is KhademModel) {
      final models = items.cast<KhademModel>();
      final firstModel = models.first;

      final relations = <dynamic>[];

      if (_withOnly.isNotEmpty) {
        relations.addAll(_withOnly);
      } else {
        // Add default relations
        relations.addAll(firstModel.withRelations);
        // Add requested relations
        relations.addAll(_with);
        // Remove excluded relations
        // Note: This simple removal only works for string matches.
        // Complex relation definitions might need more robust handling.
        relations.removeWhere((r) => _without.contains(r.toString()));
      }

      if (relations.isNotEmpty) {
        await EagerLoader.loadRelations(models, relations);
      }
    }

    return items;
  }

  @override
  Future<T?> first() async {
    limit(1);
    final results = await get();
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<T?> find(dynamic id, [String column = 'id']) async {
    return where(column, '=', id).first();
  }

  @override
  Future<T> findOrFail(dynamic id, [String column = 'id']) async {
    final result = await find(id, column);
    if (result == null) {
      throw Exception('Record not found');
    }
    return result;
  }

  @override
  Future<int> insert(Map<String, dynamic> values) async {
    final sql = grammar.compileInsert(_getQueryComponents(), values);
    final bindings = values.values.toList();
    final result = await connection.execute(sql, bindings);
    return result.insertId ?? 0;
  }

  @override
  Future<void> update(Map<String, dynamic> values) async {
    final sql = grammar.compileUpdate(_getQueryComponents(), values);
    final bindings = [...values.values, ..._bindings];
    await connection.execute(sql, bindings);
  }

  @override
  Future<void> delete() async {
    final sql = grammar.compileDelete(_getQueryComponents());
    await connection.execute(sql, _bindings);
  }

  Map<String, dynamic> _getQueryComponents() {
    return {
      'table': table,
      'columns': _columns,
      'wheres': _wheres,
      'joins': _joins,
      'groups': _groups,
      'havings': _havings,
      'orders': _orders,
      'limit': _limit,
      'offset': _offset,
      'distinct': _distinct,
      'lock': _lock,
      'unions': _unions,
    };
  }

  @override
  QueryBuilderInterface<T> join(
      String table, String first, String operator, String second,
      [String type = 'INNER',]) {
    _joins.add({
      'type': type,
      'table': table,
      'first': first,
      'operator': operator,
      'second': second,
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> leftJoin(
      String table, String first, String operator, String second,) {
    return join(table, first, operator, second, 'LEFT');
  }

  @override
  QueryBuilderInterface<T> rightJoin(
      String table, String first, String operator, String second,) {
    return join(table, first, operator, second, 'RIGHT');
  }

  @override
  QueryBuilderInterface<T> groupBy(String column) {
    _groups.add(column);
    return this;
  }

  @override
  QueryBuilderInterface<T> having(
      String column, String operator, dynamic value,) {
    _havings.add({
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': 'AND',
    });
    _bindings.add(value);
    return this;
  }

  @override
  QueryBuilderInterface<T> orHaving(
      String column, String operator, dynamic value,) {
    _havings.add({
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': 'OR',
    });
    _bindings.add(value);
    return this;
  }

  @override
  QueryBuilderInterface<T> withRelations(List relations) {
    _with.addAll(relations.map((e) => e.toString()));
    return this;
  }

  @override
  QueryBuilderInterface<T> without(List<String> relations) {
    _without.addAll(relations);
    return this;
  }

  @override
  QueryBuilderInterface<T> withOnly(List<String> relations) {
    _withOnly.addAll(relations);
    return this;
  }

  @override
  QueryBuilderInterface<T> withCount(dynamic relations) => this;

  @override
  Future<int> count() async {
    final sql = grammar.compileAggregate(
        _getQueryComponents(), {'function': 'COUNT', 'column': '*'},);
    final result = await connection.execute(sql, _bindings);
    return result.data.first['aggregate'] as int;
  }

  @override
  Future<num> sum(String column) async {
    final result = await _aggregate('SUM', column);
    return result ?? 0;
  }

  @override
  Future<num> avg(String column) async {
    final result = await _aggregate('AVG', column);
    return result ?? 0;
  }

  @override
  Future<int> max(String column) async {
    final result = await _aggregate('MAX', column);
    return (result as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> min(String column) async {
    final result = await _aggregate('MIN', column);
    return (result as num?)?.toInt() ?? 0;
  }

  Future<dynamic> _aggregate(String function, String column) async {
    final sql = grammar.compileAggregate(
        _getQueryComponents(), {'function': function, 'column': column},);
    final result = await connection.execute(sql, _bindings);
    if (result.data.isNotEmpty) {
      return result.data.first['aggregate'];
    }
    return null;
  }

  @override
  Future<bool> exists() async {
    return (await count()) > 0;
  }

  @override
  Future<PaginatedResult<T>> paginate(
      {int? page = 1, int? perPage = 15,}) async {
    final p = page ?? 1;
    final pp = perPage ?? 15;

    final total = await count();
    final lastPage = (total / pp).ceil();

    final results = await forPage(p, pp).get();

    return PaginatedResult(
      data: results,
      total: total,
      perPage: pp,
      currentPage: p,
      lastPage: lastPage,
    );
  }

  @override
  Future<Map<String, dynamic>> simplePaginate(
      {int perPage = 15, int page = 1,}) async {
    final results = await forPage(page, perPage + 1).get();
    final hasMore = results.length > perPage;
    final data = hasMore ? results.sublist(0, perPage) : results;

    return {
      'data': data,
      'per_page': perPage,
      'current_page': page,
      'next_page': hasMore ? page + 1 : null,
      'prev_page': page > 1 ? page - 1 : null,
    };
  }

  QueryBuilderInterface<T> forPage(int page, int perPage) {
    return skip((page - 1) * perPage).take(perPage);
  }

  @override
  QueryBuilderInterface<T> skip(int count) {
    _offset = count;
    return this;
  }

  @override
  QueryBuilderInterface<T> take(int count) {
    _limit = count;
    return this;
  }

  @override
  QueryBuilderInterface<T> limit(int count) => take(count);

  @override
  QueryBuilderInterface<T> offset(int count) => skip(count);

  @override
  QueryBuilderInterface<T> distinct([bool distinct = true]) {
    _distinct = distinct;
    return this;
  }

  @override
  QueryBuilderInterface<T> lockForUpdate() {
    _lock = 'FOR UPDATE';
    return this;
  }

  @override
  QueryBuilderInterface<T> sharedLock() {
    _lock = 'FOR SHARE';
    return this;
  }

  @override
  Stream<T> asStream() async* {
    for (final item in await get()) {
      yield item;
    }
  }

  @override
  Future<void> chunk(
      int size, Future<void> Function(List<T> items) callback,) async {
    int page = 1;
    List<T> results;
    do {
      final q = clone();
      q.skip((page - 1) * size).take(size);

      results = await q.get();

      if (results.isNotEmpty) {
        await callback(results);
      }

      page++;
    } while (results.length == size);
  }

  @override
  Future<void> chunkById(
      int size, Future<void> Function(List<T> items) callback,
      {String column = 'id', String? alias,}) async {
    dynamic lastId;
    List<T> results;
    do {
      final q = clone();

      if (lastId != null) {
        q.where(alias ?? column, '>', lastId);
      }

      q.orderBy(alias ?? column, direction: 'ASC');
      q.limit(size);

      results = await q.get();

      if (results.isNotEmpty) {
        await callback(results);

        final lastItem = results.last;
        if (lastItem is Map) {
          lastId = lastItem[alias ?? column];
        } else {
          try {
            lastId = (lastItem as dynamic)[alias ?? column];
          } catch (_) {
            // Fallback or error
          }
        }
      }
    } while (results.length == size);
  }

  @override
  QueryBuilderInterface<T> clone() {
    final q =
        QueryBuilder<T>(connection, grammar, table, modelFactory: modelFactory);
    q._columns = List.from(_columns);
    q._wheres.addAll(_wheres.map((e) => Map<String, dynamic>.from(e)));
    q._orders.addAll(_orders.map((e) => Map<String, dynamic>.from(e)));
    q._limit = _limit;
    q._offset = _offset;
    q._distinct = _distinct;
    q._bindings.addAll(_bindings);
    q._joins.addAll(_joins.map((e) => Map<String, dynamic>.from(e)));
    q._groups.addAll(_groups);
    q._havings.addAll(_havings.map((e) => Map<String, dynamic>.from(e)));
    q._unions.addAll(_unions.map((e) => Map<String, dynamic>.from(e)));
    q._lock = _lock;
    q._with.addAll(_with);
    q._without.addAll(_without);
    q._withOnly.addAll(_withOnly);
    return q;
  }

  @override
  QueryBuilderInterface<T> crossJoin(String table) {
    return join(table, '', '', '', 'CROSS');
  }

  @override
  Future<Map<String, dynamic>> cursorPaginate({
    int perPage = 15,
    String? cursor,
    String column = 'id',
  }) async {
    final q = clone();
    q.limit(perPage + 1);

    if (cursor != null) {
      q.where(column, '>', cursor);
    }

    q.orderBy(column, direction: 'asc');

    final results = await q.get();

    String? nextCursor;
    List<T> items = results;

    if (results.length > perPage) {
      items = results.sublist(0, perPage);
      final lastItem = items.last;
      if (lastItem is Map) {
        nextCursor = lastItem[column]?.toString();
      } else {
        try {
          nextCursor = (lastItem as dynamic)[column]?.toString();
        } catch (_) {}
      }
    }

    return {
      'data': items,
      'per_page': perPage,
      'next_cursor': nextCursor,
      'prev_cursor': null,
    };
  }

  @override
  Future<int> decrement(String column, [int amount = 1]) {
    return increment(column, -amount);
  }

  @override
  Future<int> increment(String column, [int amount = 1]) async {
    if (_wheres.isEmpty) {
      throw Exception(
          'Increment requires a WHERE clause to prevent mass updates.',);
    }
    final sql = grammar.compileIncrement(_getQueryComponents(), column, amount);
    final result = await connection.execute(sql, _bindings);
    return result.affectedRows ?? 0;
  }

  @override
  QueryBuilderInterface<T> doesntHave(String relation) {
    return whereDoesntHave(relation);
  }

  @override
  QueryBuilderInterface<T> has(String relation,
      [String operator = '>=', int count = 1,]) {
    return whereHas(relation, null, operator, count);
  }

  @override
  QueryBuilderInterface<T> whereDoesntHave(String relation,
      [void Function(QueryBuilderInterface<dynamic> query)? callback,]) {
    return whereHas(relation, callback, '<');
  }

  @override
  QueryBuilderInterface<T> orWhereRaw(String sql, [List bindings = const []]) {
    return whereRaw(sql, bindings, 'OR');
  }

  QueryBuilderInterface<T> _has(String relation, String boolean,
      [void Function(QueryBuilderInterface<dynamic> query)? callback,
      String operator = '>=',
      int count = 1,]) {
    if (modelFactory == null) {
      throw Exception('whereHas requires a model factory');
    }

    final model = modelFactory!({});
    if (model is! HasRelations) {
      throw Exception('Model does not use HasRelations trait');
    }

    // Use the new Relation object system
    final relationObj = (model as HasRelations).relation(relation);
    final relationQuery = relationObj.getRelationExistenceQuery(
      relationObj.getQuery(),
      this,
    );

    if (callback != null) {
      callback(relationQuery);
    }

    if (operator == '>=' && count == 1) {
      relationQuery.selectRaw('1');
      final sql = relationQuery.toSql();
      return whereRaw('EXISTS ($sql)', relationQuery.bindings, boolean);
    } else if (operator == '<' && count == 1) {
      relationQuery.selectRaw('1');
      final sql = relationQuery.toSql();
      return whereRaw('NOT EXISTS ($sql)', relationQuery.bindings, boolean);
    }

    relationQuery.selectRaw('COUNT(*)');
    final sql = relationQuery.toSql();
    return whereRaw(
        '($sql) $operator ?', [...relationQuery.bindings, count], boolean,);
  }

  @override
  QueryBuilderInterface<T> whereHas(String relation,
      [void Function(QueryBuilderInterface<dynamic> query)? callback,
      String operator = '>=',
      int count = 1,]) {
    return _has(relation, 'AND', callback, operator, count);
  }

  @override
  QueryBuilderInterface<T> orWhereDoesntHave(String relation,
      [void Function(QueryBuilderInterface<dynamic> query)? callback,]) {
    return orWhereHas(relation, callback, '<');
  }

  @override
  QueryBuilderInterface<T> orWhereHas(String relation,
      [void Function(QueryBuilderInterface<dynamic> query)? callback,
      String operator = '>=',
      int count = 1,]) {
    return _has(relation, 'OR', callback, operator, count);
  }

  @override
  QueryBuilderInterface<T> fromRaw(String sql, [List bindings = const []]) {
    _table = sql;
    _bindings.addAll(bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> fromSub(
      QueryBuilderInterface<dynamic> query, String alias,) {
    final subSql = (query as dynamic).toSql();
    _table = '($subSql) as $alias';
    if (query is QueryBuilder) {
      _bindings.addAll(query._bindings);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> inRandomOrder() {
    orderByRaw('RAND()');
    return this;
  }

  QueryBuilderInterface<T> orderByRaw(String sql) {
    _orders.add({
      'type': 'Raw',
      'sql': sql,
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> latest([String column = 'created_at']) =>
      orderBy(column, direction: 'DESC');

  @override
  QueryBuilderInterface<T> oldest([String column = 'created_at']) =>
      orderBy(column);

  @override
  Future<List<int>> insertMany(List<Map<String, dynamic>> values) async {
    if (values.isEmpty) return [];
    final sql = grammar.compileInsertMany(_getQueryComponents(), values);
    final bindings = values.expand((e) => e.values).toList();
    final response = await connection.execute(sql, bindings);
    final startId = response.insertId ?? 0;
    return List.generate(values.length, (i) => startId + i);
  }

  @override
  Future<int> upsert(List<Map<String, dynamic>> values,
      {required List<String> uniqueBy, List<String>? update,}) async {
    if (values.isEmpty) return 0;
    final sql =
        grammar.compileUpsert(_getQueryComponents(), values, uniqueBy, update);
    final bindings = values.expand((e) => e.values).toList() +
        (update != null
            ? values.expand((e) => update.map((c) => e[c])).toList()
            : []);
    final response = await connection.execute(sql, bindings);
    return response.affectedRows ?? 0;
  }

  @override
  Future<void> incrementEach(Map<String, int> columns,
      [Map<String, dynamic> extras = const {},]) async {
    if (_wheres.isEmpty) {
      throw Exception(
          'IncrementEach requires a WHERE clause to prevent mass updates.',);
    }
    final sql =
        grammar.compileIncrementEach(_getQueryComponents(), columns, extras);
    final bindings = extras.values.toList() + _bindings;
    await connection.execute(sql, bindings);
  }

  @override
  Stream<T> lazy([int chunkSize = 1000]) async* {
    int page = 1;
    while (true) {
      final results = await forPage(page, chunkSize).get();
      if (results.isEmpty) break;
      for (final item in results) {
        yield item;
      }
      if (results.length < chunkSize) break;
      page++;
    }
  }

  @override
  QueryBuilderInterface<T> orWhereIn(String column, List values) {
    _wheres.add({
      'type': 'In',
      'column': column,
      'values': values,
      'boolean': 'OR',
    });
    _bindings.addAll(values);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotIn(String column, List values) {
    _wheres.add({
      'type': 'NotIn',
      'column': column,
      'values': values,
      'boolean': 'OR',
    });
    _bindings.addAll(values);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNull(String column) {
    _wheres.add({
      'type': 'Null',
      'column': column,
      'boolean': 'OR',
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotNull(String column) {
    _wheres.add({
      'type': 'NotNull',
      'column': column,
      'boolean': 'OR',
    });
    return this;
  }

  @override
  Future<List<dynamic>> pluck(String column) async {
    final originalColumns = List.from(_columns);
    _columns = [column];
    final sql = grammar.compileSelect(_getQueryComponents());
    _columns = originalColumns; // Restore

    final result = await connection.execute(sql, _bindings);
    return result.data.map((row) => row[column]).toList();
  }

  @override
  QueryBuilderInterface<T> selectSub(
      QueryBuilderInterface<dynamic> query, String alias,) {
    final subSql = (query as dynamic).toSql();
    _columns.add('($subSql) as $alias');
    if (query is QueryBuilder) {
      _bindings.addAll(query._bindings);
    }
    return this;
  }

  @override
  String toSql() => grammar.compileSelect(_getQueryComponents());

  @override
  QueryBuilderInterface<T> union(QueryBuilderInterface<T> query) {
    _unions.add({
      'query': query,
      'all': false,
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> unionAll(QueryBuilderInterface<T> query) {
    _unions.add({
      'query': query,
      'all': true,
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> when(bool condition,
      QueryBuilderInterface<T> Function(QueryBuilderInterface<T> q) builder,) {
    if (condition) return builder(this);
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
  QueryBuilderInterface<T> whereAny(
      List<String> columns, String operator, value,) {
    return whereNested((q) {
      for (final column in columns) {
        q.orWhere(column, operator, value);
      }
    });
  }

  @override
  QueryBuilderInterface<T> whereNone(Map<String, dynamic> conditions) {
    if (conditions.isEmpty) return this;

    final subquery = QueryBuilder<dynamic>(connection, grammar, _table);
    conditions.forEach((column, value) {
      subquery.orWhere(column, '=', value);
    });

    final sql = grammar.compileWheres(subquery.wheres);
    // Remove leading WHERE
    final cleanSql = sql.replaceFirst('WHERE ', '');

    return whereRaw('NOT ($cleanSql)', subquery.bindings);
  }

  @override
  QueryBuilderInterface<T> whereBetweenColumns(
      String column, String startColumn, String endColumn,) {
    _wheres.add({
      'type': 'BetweenColumns',
      'column': column,
      'start': startColumn,
      'end': endColumn,
      'boolean': 'AND',
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotBetweenColumns(
      String column, String startColumn, String endColumn,) {
    _wheres.add({
      'type': 'NotBetweenColumns',
      'column': column,
      'start': startColumn,
      'end': endColumn,
      'boolean': 'AND',
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> whereColumn(
      String column1, String operator, String column2,) {
    _wheres.add({
      'type': 'Column',
      'first': column1,
      'operator': operator,
      'second': column2,
      'boolean': 'AND',
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> whereDate(String column, String date) {
    return _addDateCondition('Date', column, '=', date, 'AND');
  }

  @override
  QueryBuilderInterface<T> whereDay(String column, int day) {
    return _addDateCondition('Day', column, '=', day, 'AND');
  }

  @override
  QueryBuilderInterface<T> whereMonth(String column, int month) {
    return _addDateCondition('Month', column, '=', month, 'AND');
  }

  @override
  QueryBuilderInterface<T> whereTime(String column, String time) {
    return _addDateCondition('Time', column, '=', time, 'AND');
  }

  @override
  QueryBuilderInterface<T> whereYear(String column, int year) {
    return _addDateCondition('Year', column, '=', year, 'AND');
  }

  QueryBuilderInterface<T> _addDateCondition(String type, String column,
      String operator, dynamic value, String boolean,) {
    _wheres.add({
      'type': type,
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': boolean,
    });
    _bindings.add(value);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereExists(
      String Function(QueryBuilderInterface<dynamic> query) callback,) {
    final query = QueryBuilder<dynamic>(connection, grammar, '');
    callback(query);
    _wheres.add({
      'type': 'Exists',
      'query': query,
      'boolean': 'AND',
    });
    _bindings.addAll(query._bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereNotExists(
      String Function(QueryBuilderInterface<dynamic> query) callback,) {
    final query = QueryBuilder<dynamic>(connection, grammar, '');
    callback(query);
    _wheres.add({
      'type': 'NotExists',
      'query': query,
      'boolean': 'AND',
    });
    _bindings.addAll(query._bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereFullText(
      List<String> columns, String searchTerm,
      {String mode = 'natural',}) {
    _wheres.add({
      'type': 'FullText',
      'columns': columns,
      'value': searchTerm,
      'mode': mode,
      'boolean': 'AND',
    });
    _bindings.add(searchTerm);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereInSubquery(String column,
      String Function(QueryBuilderInterface<dynamic> query) callback,) {
    final query = QueryBuilder<dynamic>(connection, grammar, '');
    callback(query);
    _wheres.add({
      'type': 'InSub',
      'column': column,
      'query': query,
      'boolean': 'AND',
    });
    _bindings.addAll(query._bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonContains(String column, value,
      [String? path,]) {
    _wheres.add({
      'type': 'JsonContains',
      'column': column,
      'value': value,
      'path': path,
      'boolean': 'AND',
    });
    _bindings.add(value);
    if (path != null) {
      // Ensure path starts with $
      if (!path.startsWith(r'$')) path = '\$.$path';
      _bindings.add(path);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonContainsKey(String column, String path) {
    _wheres.add({
      'type': 'JsonContainsKey',
      'column': column,
      'path': path,
      'boolean': 'AND',
    });
    // Ensure path starts with $
    if (!path.startsWith(r'$')) path = '\$.$path';
    _bindings.add(path);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonDoesntContain(String column, value,
      [String? path,]) {
    _wheres.add({
      'type': 'JsonDoesntContain',
      'column': column,
      'value': value,
      'path': path,
      'boolean': 'AND',
    });
    _bindings.add(value);
    if (path != null) {
      if (!path.startsWith(r'$')) path = '\$.$path';
      _bindings.add(path);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonLength(
      String column, String operator, int length,
      [String? path,]) {
    _wheres.add({
      'type': 'JsonLength',
      'column': column,
      'operator': operator,
      'length': length,
      'path': path,
      'boolean': 'AND',
    });
    if (path != null) {
      if (!path.startsWith(r'$')) path = '\$.$path';
      _bindings.add(path);
    }
    _bindings.add(length);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereLike(String column, String pattern) =>
      where(column, 'LIKE', pattern);

  @override
  QueryBuilderInterface<T> whereNotLike(String column, String pattern) =>
      where(column, 'NOT LIKE', pattern);

  @override
  QueryBuilderInterface<T> whereNested(
      void Function(QueryBuilderInterface<T> query) callback,) {
    final query =
        QueryBuilder<T>(connection, grammar, table, modelFactory: modelFactory);
    callback(query);
    _wheres.add({
      'type': 'Nested',
      'query': query,
      'boolean': 'AND',
    });
    _bindings.addAll(query._bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNested(
      void Function(QueryBuilderInterface<T> query) callback,) {
    final query =
        QueryBuilder<T>(connection, grammar, table, modelFactory: modelFactory);
    callback(query);
    _wheres.add({
      'type': 'Nested',
      'query': query,
      'boolean': 'OR',
    });
    _bindings.addAll(query._bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> wherePast(String column) {
    return whereRaw('${grammar.wrap(column)} < NOW()');
  }

  @override
  QueryBuilderInterface<T> whereFuture(String column) {
    return whereRaw('${grammar.wrap(column)} > NOW()');
  }

  @override
  QueryBuilderInterface<T> whereToday(String column) {
    return whereRaw('DATE(${grammar.wrap(column)}) = CURDATE()');
  }

  @override
  QueryBuilderInterface<T> whereBeforeToday(String column) {
    return whereRaw('DATE(${grammar.wrap(column)}) < CURDATE()');
  }

  @override
  QueryBuilderInterface<T> whereAfterToday(String column) {
    return whereRaw('DATE(${grammar.wrap(column)}) > CURDATE()');
  }

  @override
  QueryBuilderInterface<T> withAvg(String relation, String column) => this;

  @override
  QueryBuilderInterface<T> withMax(String relation, String column) => this;

  @override
  QueryBuilderInterface<T> withMin(String relation, String column) => this;

  @override
  QueryBuilderInterface<T> withSum(String relation, String column) => this;

  @override
  QueryBuilderInterface<T> orWhereBetween(String column, start, end) {
    _wheres.add({
      'type': 'Between',
      'column': column,
      'boolean': 'OR',
    });
    _bindings.add(start);
    _bindings.add(end);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotBetween(String column, start, end) {
    _wheres.add({
      'type': 'NotBetween',
      'column': column,
      'boolean': 'OR',
    });
    _bindings.add(start);
    _bindings.add(end);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereColumn(
      String column1, String operator, String column2,) {
    _wheres.add({
      'type': 'Column',
      'first': column1,
      'operator': operator,
      'second': column2,
      'boolean': 'OR',
    });
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereDate(String column, String date) {
    return _addDateCondition('Date', column, '=', date, 'OR');
  }

  @override
  QueryBuilderInterface<T> orWhereDay(String column, int day) {
    return _addDateCondition('Day', column, '=', day, 'OR');
  }

  @override
  QueryBuilderInterface<T> orWhereMonth(String column, int month) {
    return _addDateCondition('Month', column, '=', month, 'OR');
  }

  @override
  QueryBuilderInterface<T> orWhereYear(String column, int year) {
    return _addDateCondition('Year', column, '=', year, 'OR');
  }

  @override
  QueryBuilderInterface<T> orWhereTime(String column, String time) {
    return _addDateCondition('Time', column, '=', time, 'OR');
  }

  @override
  QueryBuilderInterface<T> orWhereExists(
      String Function(QueryBuilderInterface<dynamic> query) callback,) {
    final query = QueryBuilder<dynamic>(connection, grammar, '');
    callback(query);
    _wheres.add({
      'type': 'Exists',
      'query': query,
      'boolean': 'OR',
    });
    _bindings.addAll(query._bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotExists(
      String Function(QueryBuilderInterface<dynamic> query) callback,) {
    final query = QueryBuilder<dynamic>(connection, grammar, '');
    callback(query);
    _wheres.add({
      'type': 'NotExists',
      'query': query,
      'boolean': 'OR',
    });
    _bindings.addAll(query._bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereJsonContains(String column, value,
      [String? path,]) {
    _wheres.add({
      'type': 'JsonContains',
      'column': column,
      'value': value,
      'path': path,
      'boolean': 'OR',
    });
    _bindings.add(value);
    if (path != null) {
      if (!path.startsWith(r'$')) path = '\$.$path';
      _bindings.add(path);
    }
    return this;
  }

  QueryBuilderInterface<T> orWhereJsonContainsKey(String column, String path) {
    _wheres.add({
      'type': 'JsonContainsKey',
      'column': column,
      'path': path,
      'boolean': 'OR',
    });
    if (!path.startsWith(r'$')) path = '\$.$path';
    _bindings.add(path);
    return this;
  }

  QueryBuilderInterface<T> orWhereJsonDoesntContain(String column, value,
      [String? path,]) {
    _wheres.add({
      'type': 'JsonDoesntContain',
      'column': column,
      'value': value,
      'path': path,
      'boolean': 'OR',
    });
    _bindings.add(value);
    if (path != null) {
      if (!path.startsWith(r'$')) path = '\$.$path';
      _bindings.add(path);
    }
    return this;
  }

  QueryBuilderInterface<T> orWhereJsonLength(
      String column, String operator, int length,
      [String? path,]) {
    _wheres.add({
      'type': 'JsonLength',
      'column': column,
      'operator': operator,
      'length': length,
      'path': path,
      'boolean': 'OR',
    });
    if (path != null) {
      if (!path.startsWith(r'$')) path = '\$.$path';
      _bindings.add(path);
    }
    _bindings.add(length);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereLike(String column, String pattern) =>
      orWhere(column, 'LIKE', pattern);

  @override
  QueryBuilderInterface<T> orWhereNotLike(String column, String pattern) =>
      orWhere(column, 'NOT LIKE', pattern);

  String _singular(String word) {
    if (word.endsWith('ies')) return word.substring(0, word.length - 3) + 'y';
    if (word.endsWith('s')) return word.substring(0, word.length - 1);
    return word;
  }
}

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
  // Bindings
  final List<dynamic> _selectBindings = [];
  final List<dynamic> _fromBindings = [];
  final List<dynamic> _joinBindings = [];
  final List<dynamic> _whereBindings = [];
  final List<dynamic> _havingBindings = [];

  @override
  List<dynamic> get bindings => [
        ..._selectBindings,
        ..._fromBindings,
        ..._joinBindings,
        ..._whereBindings,
        ..._havingBindings,
        ..._unions.expand((u) => (u['query'] as QueryBuilderInterface).bindings),
      ];

  final List<Map<String, dynamic>> _joins = [];
  final List<String> _groups = [];
  final List<Map<String, dynamic>> _havings = [];
  final List<Map<String, dynamic>> _unions = [];
  String? _lock;

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
    _selectBindings.addAll(bindings);
    return this;
  }

  QueryBuilderInterface<T> _addWhere(Map<String, dynamic> where,
      [List<dynamic>? bindings]) {
    _wheres.add(where);
    if (bindings != null) {
      _whereBindings.addAll(bindings);
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> where(
    String column,
    String operator,
    dynamic value,
  ) {
    return _addWhere({
      'type': 'Basic',
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': 'AND',
    }, [value]);
  }

  @override
  QueryBuilderInterface<T> orWhere(
    String column,
    String operator,
    dynamic value,
  ) {
    return _addWhere({
      'type': 'Basic',
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': 'OR',
    }, [value]);
  }

  @override
  QueryBuilderInterface<T> whereIn(String column, List<dynamic> values) {
    return _addWhere({
      'type': 'In',
      'column': column,
      'values': values,
      'boolean': 'AND',
    }, values);
  }

  @override
  QueryBuilderInterface<T> whereNotIn(String column, List<dynamic> values) {
    return _addWhere({
      'type': 'NotIn',
      'column': column,
      'values': values,
      'boolean': 'AND',
    }, values);
  }

  @override
  QueryBuilderInterface<T> whereNull(String column) {
    return _addWhere({
      'type': 'Null',
      'column': column,
      'boolean': 'AND',
    });
  }

  @override
  QueryBuilderInterface<T> whereNotNull(String column) {
    return _addWhere({
      'type': 'NotNull',
      'column': column,
      'boolean': 'AND',
    });
  }

  @override
  QueryBuilderInterface<T> whereRaw(String sql,
      [List bindings = const [], String boolean = 'AND']) {
    return _addWhere({
      'type': 'Raw',
      'sql': sql,
      'boolean': boolean,
    }, bindings);
  }

  @override
  QueryBuilderInterface<T> whereBetween(
    String column,
    dynamic start,
    dynamic end,
  ) {
    return _addWhere({
      'type': 'Between',
      'column': column,
      'values': [start, end],
      'boolean': 'AND',
    }, [start, end]);
  }

  @override
  QueryBuilderInterface<T> whereNotBetween(
    String column,
    dynamic start,
    dynamic end,
  ) {
    return _addWhere({
      'type': 'NotBetween',
      'column': column,
      'values': [start, end],
      'boolean': 'AND',
    }, [start, end]);
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
    final result = await connection.execute(sql, bindings);

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
    final bindings = [
      ..._fromBindings,
      ...values.values,
      ..._whereBindings,
    ];
    await connection.execute(sql, bindings);
  }

  @override
  Future<void> delete() async {
    final sql = grammar.compileDelete(_getQueryComponents());
    final bindings = [
      ..._fromBindings,
      ..._whereBindings,
    ];
    await connection.execute(sql, bindings);
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
    String column,
    String operator,
    dynamic value,
  ) {
    _havings.add({
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': 'AND',
    });
    _havingBindings.add(value);
    return this;
  }

  @override
  QueryBuilderInterface<T> orHaving(
    String column,
    String operator,
    dynamic value,
  ) {
    _havings.add({
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': 'OR',
    });
    _havingBindings.add(value);
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
  QueryBuilderInterface<T> withCount(dynamic relations) {
    if (modelFactory == null) {
      throw Exception('withCount requires a model factory');
    }
    final model = modelFactory!({});
    if (model is! HasRelations) {
      throw Exception('Model does not use HasRelations trait');
    }

    final Map<String, void Function(QueryBuilderInterface<dynamic>)> normalized = {};

    if (relations is String) {
      normalized[relations] = (q) {};
    } else if (relations is List) {
      for (final item in relations) {
        if (item is String) {
          normalized[item] = (q) {};
        }
      }
    } else if (relations is Map) {
      relations.forEach((key, value) {
        if (value is void Function(QueryBuilderInterface<dynamic>)) {
          normalized[key] = value;
        }
      });
    }

    normalized.forEach((relationName, callback) {
      final relationObj = (model as HasRelations).relation(relationName);
      final relationQuery = relationObj.getRelationExistenceQuery(
        relationObj.getQuery(),
        this,
      );

      callback(relationQuery);

      if (relationQuery is QueryBuilder) {
        relationQuery._columns = [];
      }

      relationQuery.selectRaw('COUNT(*)');
      selectSub(relationQuery, '${relationName}_count');
    });

    return this;
  }

  @override
  Future<int> count() async {
    final sql = grammar.compileAggregate(
      _getQueryComponents(),
      {'function': 'COUNT', 'column': '*'},
    );
    final aggregateBindings = [
      ..._fromBindings,
      ..._joinBindings,
      ..._whereBindings,
      ..._havingBindings,
    ];
    final result = await connection.execute(sql, aggregateBindings);
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
      _getQueryComponents(),
      {'function': function, 'column': column},
    );
    final aggregateBindings = [
      ..._fromBindings,
      ..._joinBindings,
      ..._whereBindings,
      ..._havingBindings,
    ];
    final result = await connection.execute(sql, aggregateBindings);
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
        final key = alias ?? column;

        if (lastItem is Map) {
          lastId = lastItem[key];
        } else if (lastItem is KhademModel) {
          lastId = (lastItem as KhademModel).getAttribute(key);
        } else {
          try {
            lastId = (lastItem as dynamic)[key];
          } catch (_) {
            throw Exception(
                'Could not determine the value of the chunk column "$key" from the result.',);
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
    q._selectBindings.addAll(_selectBindings);
    q._fromBindings.addAll(_fromBindings);
    q._joinBindings.addAll(_joinBindings);
    q._whereBindings.addAll(_whereBindings);
    q._havingBindings.addAll(_havingBindings);
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
      } else if (lastItem is KhademModel) {
        nextCursor = (lastItem as KhademModel).getAttribute(column)?.toString();
      } else {
        try {
          nextCursor = (lastItem as dynamic)[column]?.toString();
        } catch (_) {
          throw Exception(
              'Could not determine the value of the cursor column "$column" from the result.',);
        }
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
    final bindings = [
      ..._fromBindings,
      ..._whereBindings,
    ];
    final result = await connection.execute(sql, bindings);
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
    return _addWhere({
      'type': 'Raw',
      'sql': sql,
      'boolean': 'OR',
    }, bindings);
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
    _fromBindings.addAll(bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> fromSub(
    QueryBuilderInterface<dynamic> query,
    String alias,
  ) {
    final subSql = (query as dynamic).toSql();
    _table = '($subSql) as $alias';
    if (query is QueryBuilder) {
      _fromBindings.addAll(query.bindings);
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
    final bindings = [
      ..._fromBindings,
      ...extras.values,
      ..._whereBindings,
    ];
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
    return _addWhere({
      'type': 'In',
      'column': column,
      'values': values,
      'boolean': 'OR',
    }, values);
  }

  @override
  QueryBuilderInterface<T> orWhereNotIn(String column, List values) {
    return _addWhere({
      'type': 'NotIn',
      'column': column,
      'values': values,
      'boolean': 'OR',
    }, values);
  }

  @override
  QueryBuilderInterface<T> orWhereNull(String column) {
    return _addWhere({
      'type': 'Null',
      'column': column,
      'boolean': 'OR',
    });
  }

  @override
  QueryBuilderInterface<T> orWhereNotNull(String column) {
    return _addWhere({
      'type': 'NotNull',
      'column': column,
      'boolean': 'OR',
    });
  }

  @override
  Future<List<dynamic>> pluck(String column) async {
    final originalColumns = List.from(_columns);
    _columns = [column];
    final sql = grammar.compileSelect(_getQueryComponents());
    _columns = originalColumns; // Restore

    final result = await connection.execute(sql, bindings);
    return result.data.map((row) => row[column]).toList();
  }

  @override
  QueryBuilderInterface<T> selectSub(
      QueryBuilderInterface<dynamic> query, String alias,) {
    final subSql = (query as dynamic).toSql();
    _columns.add('($subSql) as $alias');
    if (query is QueryBuilder) {
      _selectBindings.addAll(query.bindings);
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

  QueryBuilderInterface<T> _addDateCondition(
    String type,
    String column,
    String operator,
    dynamic value,
    String boolean,
  ) {
    _wheres.add({
      'type': type,
      'column': column,
      'operator': operator,
      'value': value,
      'boolean': boolean,
    });
    _whereBindings.add(value);
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
    _whereBindings.addAll(query.bindings);
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
    _whereBindings.addAll(query.bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereFullText(
    List<String> columns,
    String searchTerm, {
    String mode = 'natural',
  }) {
    _wheres.add({
      'type': 'FullText',
      'columns': columns,
      'value': searchTerm,
      'mode': mode,
      'boolean': 'AND',
    });
    _whereBindings.add(searchTerm);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereInSubquery(
    String column,
    String Function(QueryBuilderInterface<dynamic> query) callback,
  ) {
    final query = QueryBuilder<dynamic>(connection, grammar, '');
    callback(query);
    _wheres.add({
      'type': 'InSub',
      'column': column,
      'query': query,
      'boolean': 'AND',
    });
    _whereBindings.addAll(query.bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonContains(
    String column,
    value, [
    String? path,
  ]) {
    _wheres.add({
      'type': 'JsonContains',
      'column': column,
      'value': value,
      'path': path,
      'boolean': 'AND',
    });
    _whereBindings.add(value);
    if (path != null) {
      _whereBindings.add(_jsonPath(path));
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
    _whereBindings.add(_jsonPath(path));
    return this;
  }

  @override
  QueryBuilderInterface<T> whereJsonDoesntContain(
    String column,
    value, [
    String? path,
  ]) {
    _wheres.add({
      'type': 'JsonDoesntContain',
      'column': column,
      'value': value,
      'path': path,
      'boolean': 'AND',
    });
    _whereBindings.add(value);
    if (path != null) {
      _whereBindings.add(_jsonPath(path));
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
    _wheres.add({
      'type': 'JsonLength',
      'column': column,
      'operator': operator,
      'length': length,
      'path': path,
      'boolean': 'AND',
    });
    if (path != null) {
      _whereBindings.add(_jsonPath(path));
    }
    _whereBindings.add(length);
    return this;
  }

  String _jsonPath(String path) {
    return path.startsWith(r'$') ? path : '\$.$path';
  }

  @override
  QueryBuilderInterface<T> whereLike(String column, String pattern) =>
      where(column, 'LIKE', pattern);

  @override
  QueryBuilderInterface<T> whereNotLike(String column, String pattern) =>
      where(column, 'NOT LIKE', pattern);

  @override
  QueryBuilderInterface<T> whereNested(
    void Function(QueryBuilderInterface<T> query) callback,
  ) {
    final query =
        QueryBuilder<T>(connection, grammar, table, modelFactory: modelFactory);
    callback(query);
    _wheres.add({
      'type': 'Nested',
      'query': query,
      'boolean': 'AND',
    });
    _whereBindings.addAll(query.bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNested(
    void Function(QueryBuilderInterface<T> query) callback,
  ) {
    final query =
        QueryBuilder<T>(connection, grammar, table, modelFactory: modelFactory);
    callback(query);
    _wheres.add({
      'type': 'Nested',
      'query': query,
      'boolean': 'OR',
    });
    _whereBindings.addAll(query.bindings);
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
  QueryBuilderInterface<T> withAvg(String relation, String column) =>
      _withAggregate(relation, 'AVG', column);

  @override
  QueryBuilderInterface<T> withMax(String relation, String column) =>
      _withAggregate(relation, 'MAX', column);

  @override
  QueryBuilderInterface<T> withMin(String relation, String column) =>
      _withAggregate(relation, 'MIN', column);

  @override
  QueryBuilderInterface<T> withSum(String relation, String column) =>
      _withAggregate(relation, 'SUM', column);

  QueryBuilderInterface<T> _withAggregate(
      String relationName, String function, String column,) {
    if (modelFactory == null) {
      throw Exception('withAggregate requires a model factory');
    }
    final model = modelFactory!({});
    if (model is! HasRelations) {
      throw Exception('Model does not use HasRelations trait');
    }

    final relationObj = (model as HasRelations).relation(relationName);
    final relationQuery = relationObj.getRelationExistenceQuery(
      relationObj.getQuery(),
      this,
    );

    if (relationQuery is QueryBuilder) {
      relationQuery._columns = [];
    }

    relationQuery.selectRaw('$function(${grammar.wrap(column)})');
    selectSub(
        relationQuery, '${relationName}_${function.toLowerCase()}_$column',);

    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereBetween(String column, start, end) {
    _wheres.add({
      'type': 'Between',
      'column': column,
      'values': [start, end],
      'boolean': 'OR',
    });
    _whereBindings.add(start);
    _whereBindings.add(end);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereNotBetween(String column, start, end) {
    _wheres.add({
      'type': 'NotBetween',
      'column': column,
      'values': [start, end],
      'boolean': 'OR',
    });
    _whereBindings.add(start);
    _whereBindings.add(end);
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
    _whereBindings.addAll(query.bindings);
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
    _whereBindings.addAll(query.bindings);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereJsonContains(
    String column,
    value, [
    String? path,
  ]) {
    _wheres.add({
      'type': 'JsonContains',
      'column': column,
      'value': value,
      'path': path,
      'boolean': 'OR',
    });
    _whereBindings.add(value);
    if (path != null) {
      _whereBindings.add(_jsonPath(path));
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereJsonContainsKey(String column, String path) {
    _wheres.add({
      'type': 'JsonContainsKey',
      'column': column,
      'path': path,
      'boolean': 'OR',
    });
    _whereBindings.add(_jsonPath(path));
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereJsonDoesntContain(
    String column,
    value, [
    String? path,
  ]) {
    _wheres.add({
      'type': 'JsonDoesntContain',
      'column': column,
      'value': value,
      'path': path,
      'boolean': 'OR',
    });
    _whereBindings.add(value);
    if (path != null) {
      _whereBindings.add(_jsonPath(path));
    }
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereJsonLength(
    String column,
    String operator,
    int length, [
    String? path,
  ]) {
    _wheres.add({
      'type': 'JsonLength',
      'column': column,
      'operator': operator,
      'length': length,
      'path': path,
      'boolean': 'OR',
    });
    if (path != null) {
      _whereBindings.add(_jsonPath(path));
    }
    _whereBindings.add(length);
    return this;
  }

  @override
  QueryBuilderInterface<T> orWhereLike(String column, String pattern) =>
      orWhere(column, 'LIKE', pattern);

  @override
  QueryBuilderInterface<T> orWhereNotLike(String column, String pattern) =>
      orWhere(column, 'NOT LIKE', pattern);
}

/// Base class for database query grammars.
///
/// Responsible for compiling query components into SQL strings.
abstract class Grammar {
  /// The components that make up a select clause.
  List<String> selectComponents = [
    'aggregate',
    'columns',
    'from',
    'joins',
    'wheres',
    'groups',
    'havings',
    'orders',
    'limit',
    'offset',
    'lock',
  ];

  /// Wrap a value in keyword identifiers.
  String wrap(String value) {
    if (value == '*') return value;
    return '"$value"';
  }

  /// Wrap a table in keyword identifiers.
  String wrapTable(String table) {
    return wrap(table);
  }

  /// Compile a select query into SQL.
  String compileSelect(Map<String, dynamic> query);

  /// Compile an insert statement into SQL.
  String compileInsert(Map<String, dynamic> query, Map<String, dynamic> values);

  /// Compile an update statement into SQL.
  String compileUpdate(Map<String, dynamic> query, Map<String, dynamic> values);

  /// Compile a delete statement into SQL.
  String compileDelete(Map<String, dynamic> query);

  /// Compile an increment statement into SQL.
  String compileIncrement(
    Map<String, dynamic> query,
    String column,
    int amount,
  );

  /// Compile an insert statement with multiple rows.
  String compileInsertMany(
    Map<String, dynamic> query,
    List<Map<String, dynamic>> values,
  );

  /// Compile an upsert statement.
  String compileUpsert(
    Map<String, dynamic> query,
    List<Map<String, dynamic>> values,
    List<String> uniqueBy, [
    List<String>? update,
  ]);

  /// Compile an increment each statement.
  String compileIncrementEach(
    Map<String, dynamic> query,
    Map<String, int> columns,
    Map<String, dynamic> extras,
  );

  /// Compile the "from" portion of the query.
  String compileFrom(String table) {
    return 'FROM ${wrapTable(table)}';
  }

  /// Compile the "where" portion of the query.
  String compileWheres(List<Map<String, dynamic>> wheres) {
    if (wheres.isEmpty) return '';

    final lines = <String>[];
    for (final where in wheres) {
      final type = where['type'] as String;
      final boolean = where['boolean'] as String;

      String sql;
      switch (type) {
        case 'Raw':
          sql = where['sql'];
          break;
        case 'Basic':
          sql = '${wrap(where['column'])} ${where['operator']} ?';
          break;
        case 'In':
          final values = where['values'] as List;
          if (values.isEmpty) {
            sql = '0 = 1';
          } else {
            final placeholders = List.filled(values.length, '?').join(', ');
            sql = '${wrap(where['column'])} IN ($placeholders)';
          }
          break;
        case 'NotIn':
          final values = where['values'] as List;
          if (values.isEmpty) {
            sql = '1 = 1';
          } else {
            final placeholders = List.filled(values.length, '?').join(', ');
            sql = '${wrap(where['column'])} NOT IN ($placeholders)';
          }
          break;
        case 'Null':
          sql = '${wrap(where['column'])} IS NULL';
          break;
        case 'NotNull':
          sql = '${wrap(where['column'])} IS NOT NULL';
          break;
        case 'Between':
          sql = '${wrap(where['column'])} BETWEEN ? AND ?';
          break;
        case 'NotBetween':
          sql = '${wrap(where['column'])} NOT BETWEEN ? AND ?';
          break;
        case 'Date':
          sql = 'DATE(${wrap(where['column'])}) ${where['operator']} ?';
          break;
        case 'Time':
          sql = 'TIME(${wrap(where['column'])}) ${where['operator']} ?';
          break;
        case 'Year':
          sql = 'YEAR(${wrap(where['column'])}) ${where['operator']} ?';
          break;
        case 'Month':
          sql = 'MONTH(${wrap(where['column'])}) ${where['operator']} ?';
          break;
        case 'Day':
          sql = 'DAY(${wrap(where['column'])}) ${where['operator']} ?';
          break;
        case 'Column':
          sql =
              '${wrap(where['first'])} ${where['operator']} ${wrap(where['second'])}';
          break;
        case 'Nested':
          final nestedQuery = where['query'];
          final nestedWheres =
              (nestedQuery as dynamic).wheres as List<Map<String, dynamic>>;

          final nestedSql = compileWheres(nestedWheres);
          if (nestedSql.isEmpty) continue;

          // Remove leading WHERE and boolean if present (AND/OR)
          var cleanSql = nestedSql.replaceFirst('WHERE ', '');
          cleanSql = cleanSql.replaceFirst(RegExp(r'^(AND|OR)\s+'), '');
          sql = '($cleanSql)';
          break;
        case 'InSub':
          final subquery = (where['query'] as dynamic).toSql();
          sql = '${wrap(where['column'])} IN ($subquery)';
          break;
        case 'Exists':
          final subquery = (where['query'] as dynamic).toSql();
          sql = 'EXISTS ($subquery)';
          break;
        case 'NotExists':
          final subquery = (where['query'] as dynamic).toSql();
          sql = 'NOT EXISTS ($subquery)';
          break;
        case 'FullText':
          final columns = (where['columns'] as List<String>)
              .map(wrap)
              .join(', ');
          final mode = where['mode'] == 'boolean'
              ? 'IN BOOLEAN MODE'
              : where['mode'] == 'query_expansion' ||
                    where['mode'] == 'expansion'
              ? 'WITH QUERY EXPANSION'
              : 'IN NATURAL LANGUAGE MODE';
          sql = 'MATCH ($columns) AGAINST (? $mode)';
          break;
        case 'BetweenColumns':
          sql =
              '${wrap(where['column'])} BETWEEN ${wrap(where['start'])} AND ${wrap(where['end'])}';
          break;
        case 'NotBetweenColumns':
          sql =
              '${wrap(where['column'])} NOT BETWEEN ${wrap(where['start'])} AND ${wrap(where['end'])}';
          break;
        case 'JsonContains':
          final path = where['path'] != null ? ', ?' : '';
          sql = 'JSON_CONTAINS(${wrap(where['column'])}, ?$path)';
          break;
        case 'JsonContainsKey':
          sql = 'JSON_CONTAINS_PATH(${wrap(where['column'])}, \'one\', ?)';
          break;
        case 'JsonDoesntContain':
          final path = where['path'] != null ? ', ?' : '';
          sql = 'NOT JSON_CONTAINS(${wrap(where['column'])}, ?$path)';
          break;
        case 'JsonLength':
          final path = where['path'] != null ? ', ?' : '';
          sql =
              'JSON_LENGTH(${wrap(where['column'])}$path) ${where['operator']} ?';
          break;
        default:
          continue;
      }

      if (lines.isNotEmpty) {
        sql = '$boolean $sql';
      }
      lines.add(sql);
    }

    if (lines.isEmpty) return '';
    return 'WHERE ${lines.join(' ')}';
  }

  /// Compile the "join" portion of the query.
  String compileJoins(List<Map<String, dynamic>> joins) {
    return joins
        .map((join) {
          final table = wrapTable(join['table']);
          final type = join['type'];
          final first = wrap(join['first']);
          final operator = join['operator'];
          final second = wrap(join['second']);

          return '$type JOIN $table ON $first $operator $second';
        })
        .join(' ');
  }

  /// Compile the "group by" portion of the query.
  String compileGroups(List<String> groups) {
    if (groups.isEmpty) return '';
    return 'GROUP BY ${groups.map(wrap).join(', ')}';
  }

  /// Compile the "having" portion of the query.
  String compileHavings(List<Map<String, dynamic>> havings) {
    if (havings.isEmpty) return '';
    final sql = havings
        .map((having) {
          final column = wrap(having['column']);
          final operator = having['operator'];
          return '$column $operator ?';
        })
        .join(' AND ');

    return 'HAVING $sql';
  }

  /// Compile the "limit" portion of the query.
  String compileLimit(int limit) {
    return 'LIMIT $limit';
  }

  /// Compile the "offset" portion of the query.
  String compileOffset(int offset) {
    return 'OFFSET $offset';
  }

  /// Compile the "order by" portion of the query.
  String compileOrders(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) return '';

    final lines = orders.map((order) {
      if (order['type'] == 'Raw') return order['sql'];
      return '${wrap(order['column'])} ${order['direction']}';
    }).toList();

    return 'ORDER BY ${lines.join(', ')}';
  }

  /// Compile an aggregate query (count, max, min, etc.).
  String compileAggregate(
    Map<String, dynamic> query,
    Map<String, dynamic> aggregate,
  ) {
    // Temporarily replace columns with aggregate
    final originalColumns = query['columns'];
    query['columns'] = [
      {
        'type': 'Raw',
        'sql': '${aggregate['function']}(${aggregate['column']}) as aggregate',
      },
    ];

    final sql = compileSelect(query);

    // Restore
    query['columns'] = originalColumns;

    return sql;
  }
}

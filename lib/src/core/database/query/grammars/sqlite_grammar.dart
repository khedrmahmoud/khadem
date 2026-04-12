import '../grammar.dart';

/// SQLite specific grammar implementation.
class SQLiteGrammar extends Grammar {
  @override
  String wrap(String value) {
    if (value == '*') return value;
    if (value.startsWith('(')) return value; // Subquery or expression

    if (value.contains('.')) {
      return value
          .split('.')
          .map((part) {
            if (part == '*') return part;
            return '"$part"';
          })
          .join('.');
    }
    return '"$value"';
  }

  @override
  String compileSelect(Map<String, dynamic> query) {
    final components = <String>[];

    // Columns
    final columns = query['columns'] as List<dynamic>?;
    final distinct = query['distinct'] as bool? ?? false;
    final select = distinct ? 'SELECT DISTINCT' : 'SELECT';

    if (columns == null || columns.isEmpty) {
      components.add('$select *');
    } else {
      components.add(
        '$select ${columns.map((c) {
          if (c is Map && c['type'] == 'Raw') return c['sql'];
          return wrap(c.toString());
        }).join(', ')}',
      );
    }

    // From
    if (query['table'] != null) {
      components.add(compileFrom(query['table']));
    }

    // Joins
    if (query['joins'] != null) {
      final joins = compileJoins(query['joins']);
      if (joins.isNotEmpty) components.add(joins);
    }

    // Wheres
    if (query['wheres'] != null) {
      final wheres = compileWheres(query['wheres']);
      if (wheres.isNotEmpty) {
        components.add(wheres);
      }
    }

    // Groups
    if (query['groups'] != null) {
      final groups = compileGroups(query['groups']);
      if (groups.isNotEmpty) components.add(groups);
    }

    // Havings
    if (query['havings'] != null) {
      final havings = compileHavings(query['havings']);
      if (havings.isNotEmpty) components.add(havings);
    }

    // Orders
    if (query['orders'] != null) {
      final orders = compileOrders(query['orders']);
      if (orders.isNotEmpty) components.add(orders);
    }

    // Limit
    if (query['limit'] != null) {
      components.add('LIMIT ${query['limit']}');
    }

    // Offset
    if (query['offset'] != null) {
      components.add('OFFSET ${query['offset']}');
    }

    // Lock (Not supported in SQLite in the same way, usually ignored or handled differently)
    // We'll ignore it for now or just append if user insists, but SQLite might error.

    // Unions
    if (query['unions'] != null && (query['unions'] as List).isNotEmpty) {
      components.add(compileUnions(query['unions']));
    }

    return components.join(' ');
  }

  @override
  String compileFrom(String table) {
    return 'FROM ${wrapTable(table)}';
  }

  @override
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

  @override
  String compileWheres(List<Map<String, dynamic>> wheres) {
    if (wheres.isEmpty) return '';

    final sql = wheres
        .map((where) {
          final boolean = where['boolean'];
          final type = where['type'];
          String segment = '';

          if (type == 'Basic') {
            segment = '${wrap(where['column'])} ${where['operator']} ?';
          } else if (type == 'Null') {
            segment = '${wrap(where['column'])} IS NULL';
          } else if (type == 'NotNull') {
            segment = '${wrap(where['column'])} IS NOT NULL';
          } else if (type == 'In') {
            final values = (where['values'] as List).map((_) => '?').join(', ');
            segment = '${wrap(where['column'])} IN ($values)';
          } else if (type == 'NotIn') {
            final values = (where['values'] as List).map((_) => '?').join(', ');
            segment = '${wrap(where['column'])} NOT IN ($values)';
          } else if (type == 'Between') {
            segment = '${wrap(where['column'])} BETWEEN ? AND ?';
          } else if (type == 'NotBetween') {
            segment = '${wrap(where['column'])} NOT BETWEEN ? AND ?';
          } else if (type == 'Column') {
            segment =
                '${wrap(where['first'])} ${where['operator']} ${wrap(where['second'])}';
          } else if (type == 'BetweenColumns') {
            segment =
                '${wrap(where['column'])} BETWEEN ${wrap(where['start'])} AND ${wrap(where['end'])}';
          } else if (type == 'NotBetweenColumns') {
            segment =
                '${wrap(where['column'])} NOT BETWEEN ${wrap(where['start'])} AND ${wrap(where['end'])}';
          } else if (type == 'Date') {
            segment = 'DATE(${wrap(where['column'])}) ${where['operator']} ?';
          } else if (type == 'Year') {
            segment =
                'strftime(\'%Y\', ${wrap(where['column'])}) ${where['operator']} ?';
          } else if (type == 'Month') {
            segment =
                'strftime(\'%m\', ${wrap(where['column'])}) ${where['operator']} ?';
          } else if (type == 'Day') {
            segment =
                'strftime(\'%d\', ${wrap(where['column'])}) ${where['operator']} ?';
          } else if (type == 'Raw') {
            segment = where['sql'];
          } else if (type == 'Nested') {
            final nestedSql = compileWheres(where['query'].wheres);
            if (nestedSql.isNotEmpty) {
              final cleanedSql = nestedSql
                  .replaceFirst('WHERE ', '')
                  .replaceFirst(RegExp(r'^(AND|OR) '), '');
              segment = '($cleanedSql)';
            }
          } else if (type == 'Exists') {
            final subquery = (where['query'] as dynamic).toSql();
            segment = 'EXISTS ($subquery)';
          } else if (type == 'NotExists') {
            final subquery = (where['query'] as dynamic).toSql();
            segment = 'NOT EXISTS ($subquery)';
          } else if (type == 'InSub') {
            final subquery = (where['query'] as dynamic).toSql();
            segment = '${wrap(where['column'])} IN ($subquery)';
          } else if (type == 'NotInSub') {
            final subquery = (where['query'] as dynamic).toSql();
            segment = '${wrap(where['column'])} NOT IN ($subquery)';
          }

          if (segment.isEmpty) return '';
          return '$boolean $segment';
        })
        .where((s) => s.isNotEmpty)
        .join(' ');

    if (sql.isEmpty) return '';

    return 'WHERE ' + sql.replaceFirst(RegExp(r'^(AND|OR) '), '');
  }

  @override
  String compileGroups(List<String> groups) {
    if (groups.isEmpty) return '';
    return 'GROUP BY ${groups.map(wrap).join(', ')}';
  }

  @override
  String compileHavings(List<Map<String, dynamic>> havings) {
    if (havings.isEmpty) return '';
    // Similar to wheres but for HAVING
    final sql = havings
        .map((having) {
          final boolean = having['boolean'];
          return '$boolean ${wrap(having['column'])} ${having['operator']} ?';
        })
        .join(' ');

    return 'HAVING ' + sql.replaceFirst(RegExp(r'^(AND|OR) '), '');
  }

  @override
  String compileOrders(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) return '';
    return 'ORDER BY ${orders.map((order) {
      return '${wrap(order['column'])} ${order['direction']}';
    }).join(', ')}';
  }

  String compileUnions(List<Map<String, dynamic>> unions) {
    String sql = '';
    for (final union in unions) {
      final joiner = union['all'] ? ' UNION ALL ' : ' UNION ';
      sql += joiner + (union['query'] as dynamic).toSql();
    }
    return sql;
  }

  @override
  String compileInsert(
    Map<String, dynamic> query,
    Map<String, dynamic> values,
  ) {
    final table = wrapTable(query['table']);
    final columns = values.keys.map(wrap).join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');

    return 'INSERT INTO $table ($columns) VALUES ($placeholders)';
  }

  @override
  String compileInsertMany(
    Map<String, dynamic> query,
    List<Map<String, dynamic>> values,
  ) {
    final table = wrapTable(query['table']);
    final columns = values.first.keys.map(wrap).join(', ');
    final rowPlaceholders =
        '(${List.filled(values.first.length, '?').join(', ')})';
    final placeholders = List.filled(values.length, rowPlaceholders).join(', ');

    return 'INSERT INTO $table ($columns) VALUES $placeholders';
  }

  @override
  String compileUpsert(
    Map<String, dynamic> query,
    List<Map<String, dynamic>> values,
    List<String> uniqueBy, [
    List<String>? update,
  ]) {
    final sql = compileInsertMany(query, values);
    final columns = update ?? values.first.keys.toList();

    final updateSql = columns
        .map((col) {
          final wrapped = wrap(col);
          return '$wrapped = excluded.$wrapped';
        })
        .join(', ');

    final conflictCols = uniqueBy.map(wrap).join(', ');

    return '$sql ON CONFLICT ($conflictCols) DO UPDATE SET $updateSql';
  }

  @override
  String compileUpdate(
    Map<String, dynamic> query,
    Map<String, dynamic> values,
  ) {
    final table = wrapTable(query['table']);
    final columns = values.keys.map((key) => '${wrap(key)} = ?').join(', ');
    final wheres = compileWheres(query['wheres'] ?? []);

    return 'UPDATE $table SET $columns $wheres'.trim();
  }

  @override
  String compileDelete(Map<String, dynamic> query) {
    final table = wrapTable(query['table']);
    final wheres = compileWheres(query['wheres'] ?? []);

    return 'DELETE FROM $table $wheres'.trim();
  }

  @override
  String compileIncrement(
    Map<String, dynamic> query,
    String column,
    int amount,
  ) {
    final table = wrapTable(query['table']);
    final wrappedCol = wrap(column);
    final wheres = compileWheres(query['wheres'] ?? []);

    final sign = amount >= 0 ? '+' : '-';
    final absAmount = amount.abs();

    return 'UPDATE $table SET $wrappedCol = $wrappedCol $sign $absAmount $wheres'
        .trim();
  }

  @override
  String compileIncrementEach(
    Map<String, dynamic> query,
    Map<String, int> columns,
    Map<String, dynamic> extras,
  ) {
    final table = wrapTable(query['table']);
    final wheres = compileWheres(query['wheres'] ?? []);

    final updates = <String>[];

    columns.forEach((col, amount) {
      final wrapped = wrap(col);
      final sign = amount >= 0 ? '+' : '-';
      updates.add('$wrapped = $wrapped $sign ${amount.abs()}');
    });

    extras.forEach((col, value) {
      updates.add('${wrap(col)} = ?');
    });

    return 'UPDATE $table SET ${updates.join(', ')} $wheres'.trim();
  }

  String compileInsertOrIgnore(
    Map<String, dynamic> query,
    Map<String, dynamic> values,
  ) {
    final table = wrapTable(query['table']);
    final columns = values.keys.map(wrap).join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');

    return 'INSERT OR IGNORE INTO $table ($columns) VALUES ($placeholders)';
  }
}

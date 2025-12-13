import '../grammar.dart';

/// MySQL specific grammar implementation.
class MySQLGrammar extends Grammar {
  @override
  String wrap(String value) {
    if (value == '*') return value;
    if (value.startsWith('(')) return value;
    // Don't wrap if already wrapped or contains spaces/dots (simple heuristic)
    // Actually, we should split by dot and wrap each part.
    if (value.contains('.')) {
      return value.split('.').map((part) {
        if (part == '*') return part;
        return '`$part`';
      }).join('.');
    }
    return '`$value`';
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
      components.add('$select ${columns.map((c) {
        if (c is Map && c['type'] == 'Raw') return c['sql'];
        return wrap(c.toString());
      }).join(', ')}');
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
      components.add(compileLimit(query['limit']));
    }

    // Offset
    if (query['offset'] != null) {
      components.add(compileOffset(query['offset']));
    }

    // Lock
    if (query['lock'] != null) {
      components.add(query['lock']);
    }

    // Unions
    if (query['unions'] != null && (query['unions'] as List).isNotEmpty) {
      components.add(compileUnions(query['unions']));
    }

    return components.join(' ');
  }

  String compileUnions(List<Map<String, dynamic>> unions) {
    String sql = '';
    for (final union in unions) {
      sql += compileUnion(union);
    }
    return sql;
  }

  String compileUnion(Map<String, dynamic> union) {
    final joiner = union['all'] ? ' UNION ALL ' : ' UNION ';
    return joiner + (union['query'] as dynamic).toSql();
  }

  @override
  String compileInsert(Map<String, dynamic> query, Map<String, dynamic> values) {
    final table = wrapTable(query['table']);
    final columns = values.keys.map(wrap).join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');

    return 'INSERT INTO $table ($columns) VALUES ($placeholders)';
  }

  @override
  String compileUpdate(Map<String, dynamic> query, Map<String, dynamic> values) {
    final table = wrapTable(query['table']);
    final columns = values.keys.map((key) => '${wrap(key)} = ?').join(', ');
    final wheres = query['wheres'] != null ? compileWheres(query['wheres']) : '';

    return 'UPDATE $table SET $columns $wheres'.trim();
  }

  @override
  String compileDelete(Map<String, dynamic> query) {
    final table = wrapTable(query['table']);
    final wheres = query['wheres'] != null ? compileWheres(query['wheres']) : '';

    return 'DELETE FROM $table $wheres'.trim();
  }

  @override
  String compileIncrement(Map<String, dynamic> query, String column, int amount) {
    final table = wrapTable(query['table']);
    final wheres = query['wheres'] != null ? compileWheres(query['wheres']) : '';
    final wrappedColumn = wrap(column);
    final operator = amount >= 0 ? '+' : '-';
    final absAmount = amount.abs();

    return 'UPDATE $table SET $wrappedColumn = $wrappedColumn $operator $absAmount $wheres'.trim();
  }

  @override
  String compileInsertMany(Map<String, dynamic> query, List<Map<String, dynamic>> values) {
    final table = wrapTable(query['table']);
    final first = values.first;
    final columns = first.keys.map(wrap).join(', ');
    
    final placeholders = values.map((row) {
      return '(${List.filled(row.length, '?').join(', ')})';
    }).join(', ');

    return 'INSERT INTO $table ($columns) VALUES $placeholders';
  }

  @override
  String compileUpsert(Map<String, dynamic> query, List<Map<String, dynamic>> values, List<String> uniqueBy, [List<String>? update]) {
    final sql = compileInsertMany(query, values);
    
    final updateColumns = update ?? values.first.keys.where((k) => !uniqueBy.contains(k)).toList();
    
    final updates = updateColumns.map((col) {
      final wrapped = wrap(col);
      return '$wrapped = VALUES($wrapped)';
    }).join(', ');
    
    return '$sql ON DUPLICATE KEY UPDATE $updates';
  }

  @override
  String compileIncrementEach(Map<String, dynamic> query, Map<String, int> columns, Map<String, dynamic> extras) {
    final table = wrapTable(query['table']);
    final wheres = query['wheres'] != null ? compileWheres(query['wheres']) : '';
    
    final columnUpdates = columns.entries.map((e) {
      final wrapped = wrap(e.key);
      final operator = e.value >= 0 ? '+' : '-';
      return '$wrapped = $wrapped $operator ${e.value.abs()}';
    }).toList();
    
    final extraUpdates = extras.keys.map((key) {
      return '${wrap(key)} = ?';
    }).toList();
    
    final allUpdates = [...columnUpdates, ...extraUpdates].join(', ');

    return 'UPDATE $table SET $allUpdates $wheres'.trim();
  }
}

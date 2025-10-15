import 'package:khadem/src/contracts/database/connection_interface.dart';
import 'package:khadem/src/contracts/database/database_response.dart';
import 'package:khadem/src/contracts/database/query_builder_interface.dart';
import 'package:khadem/src/core/database/database_drivers/mysql/mysql_query_builder.dart';
import 'package:test/test.dart';

// Simple mock connection for testing SQL generation
class _MockConnection implements ConnectionInterface {
  @override
  Future<DatabaseResponse> execute(String query,
      [List<dynamic> bindings = const [],]) async {
    return DatabaseResponse(data: [], insertId: 1, affectedRows: 0);
  }

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  bool get isConnected => true;

  @override
  QueryBuilderInterface<T> queryBuilder<T>(
    String table, {
    T Function(Map<String, dynamic>)? modelFactory,
  }) {
    return MySQLQueryBuilder<T>(this, table, modelFactory: modelFactory);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function() callback, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
    Future<void> Function(T result)? onSuccess,
    Future<void> Function(dynamic error)? onFailure,
    Future<void> Function()? onFinally,
  }) async {
    return callback();
  }

  @override
  Future<bool> ping() async => true;
}

void main() {
  late ConnectionInterface mockConnection;
  late QueryBuilderInterface<Map<String, dynamic>> queryBuilder;

  setUp(() {
    mockConnection = _MockConnection();
    queryBuilder = MySQLQueryBuilder<Map<String, dynamic>>(
      mockConnection,
      'users',
    );
  });

  group('Phase 2: JOIN Operations', () {
    group('join', () {
      test('builds correct INNER JOIN SQL', () {
        queryBuilder.join('posts', 'users.id', '=', 'posts.user_id');

        final sql = queryBuilder.toSql();
        expect(
          sql,
          contains('INNER JOIN `posts` ON `users.id` = `posts.user_id`'),
        );
      });

      test('supports multiple joins', () {
        queryBuilder
            .join('posts', 'users.id', '=', 'posts.user_id')
            .join('comments', 'posts.id', '=', 'comments.post_id');

        final sql = queryBuilder.toSql();
        expect(sql, contains('INNER JOIN `posts`'));
        expect(sql, contains('INNER JOIN `comments`'));
      });

      test('chains with WHERE clauses', () {
        queryBuilder
            .join('posts', 'users.id', '=', 'posts.user_id')
            .where('users.active', '=', true);

        final sql = queryBuilder.toSql();
        expect(sql, contains('INNER JOIN `posts`'));
        expect(sql, contains('WHERE `users.active` = ?'));
      });
    });

    group('leftJoin', () {
      test('builds correct LEFT JOIN SQL', () {
        queryBuilder.leftJoin('profiles', 'users.id', '=', 'profiles.user_id');

        final sql = queryBuilder.toSql();
        expect(
          sql,
          contains('LEFT JOIN `profiles` ON `users.id` = `profiles.user_id`'),
        );
      });

      test('combines LEFT JOIN with INNER JOIN', () {
        queryBuilder
            .join('posts', 'users.id', '=', 'posts.user_id')
            .leftJoin('profiles', 'users.id', '=', 'profiles.user_id');

        final sql = queryBuilder.toSql();
        expect(sql, contains('INNER JOIN `posts`'));
        expect(sql, contains('LEFT JOIN `profiles`'));
      });
    });

    group('rightJoin', () {
      test('builds correct RIGHT JOIN SQL', () {
        queryBuilder.rightJoin('settings', 'users.id', '=', 'settings.user_id');

        final sql = queryBuilder.toSql();
        expect(
          sql,
          contains('RIGHT JOIN `settings` ON `users.id` = `settings.user_id`'),
        );
      });
    });

    group('crossJoin', () {
      test('builds correct CROSS JOIN SQL', () {
        queryBuilder.crossJoin('roles');

        final sql = queryBuilder.toSql();
        expect(sql, contains('CROSS JOIN `roles`'));
      });

      test('combines with WHERE clause', () {
        queryBuilder.crossJoin('roles').where('users.active', '=', true);

        final sql = queryBuilder.toSql();
        expect(sql, contains('CROSS JOIN `roles`'));
        expect(sql, contains('WHERE `users.active` = ?'));
      });
    });

    group('complex joins', () {
      test('combines multiple join types', () {
        queryBuilder
            .select(['users.*', 'posts.title', 'profiles.bio'])
            .join('posts', 'users.id', '=', 'posts.user_id')
            .leftJoin('profiles', 'users.id', '=', 'profiles.user_id')
            .where('posts.published', '=', true)
            .orderBy('posts.created_at', direction: 'DESC');

        final sql = queryBuilder.toSql();
        expect(sql, contains('SELECT users.*, posts.title, profiles.bio'));
        expect(sql, contains('INNER JOIN `posts`'));
        expect(sql, contains('LEFT JOIN `profiles`'));
        expect(sql, contains('WHERE `posts.published` = ?'));
        expect(sql, contains('ORDER BY `posts.created_at` DESC'));
      });
    });
  });

  group('Phase 3: Bulk Operations', () {
    group('insertMany', () {
      test('returns list of IDs for multiple inserts', () async {
        final ids = await queryBuilder.insertMany([
          {'name': 'John', 'email': 'john@test.com'},
          {'name': 'Jane', 'email': 'jane@test.com'},
          {'name': 'Bob', 'email': 'bob@test.com'},
        ]);

        expect(ids, isA<List<int>>());
        expect(ids.length, equals(3));
      });

      test('returns empty list for empty input', () async {
        final ids = await queryBuilder.insertMany([]);

        expect(ids, isEmpty);
      });
    });

    group('upsert', () {
      test('performs insert or update', () async {
        final affected = await queryBuilder.upsert(
          [
            {'email': 'john@test.com', 'name': 'John Doe'},
            {'email': 'jane@test.com', 'name': 'Jane Doe'},
          ],
          uniqueBy: ['email'],
          update: ['name'],
        );

        expect(affected, isA<int>());
      });

      test('handles empty rows', () async {
        final affected = await queryBuilder.upsert(
          [],
          uniqueBy: ['email'],
        );

        expect(affected, equals(0));
      });
    });

    group('increment', () {
      test('increments column by default amount', () async {
        queryBuilder.where('id', '=', 1);
        final affected = await queryBuilder.increment('view_count');

        expect(affected, isA<int>());
      });

      test('increments column by custom amount', () async {
        queryBuilder.where('id', '=', 1);
        final affected = await queryBuilder.increment('score', 10);

        expect(affected, isA<int>());
      });

      test('throws without WHERE clause', () async {
        expect(
          () => queryBuilder.increment('view_count'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('decrement', () {
      test('decrements column by default amount', () async {
        queryBuilder.where('id', '=', 1);
        final affected = await queryBuilder.decrement('stock');

        expect(affected, isA<int>());
      });

      test('decrements column by custom amount', () async {
        queryBuilder.where('id', '=', 1);
        final affected = await queryBuilder.decrement('balance', 50);

        expect(affected, isA<int>());
      });
    });

    group('incrementEach', () {
      test('increments multiple columns', () async {
        queryBuilder.where('id', '=', 1);

        await queryBuilder.incrementEach({
          'view_count': 1,
          'share_count': 1,
          'like_count': 2,
        });

        // Should not throw
      });

      test('throws without WHERE clause', () async {
        expect(
          () => queryBuilder.incrementEach({'view_count': 1}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('lazy', () {
      test('returns a stream', () {
        final stream = queryBuilder.lazy(50);

        expect(stream, isA<Stream<Map<String, dynamic>>>());
      });

      test('uses custom chunk size', () {
        final stream = queryBuilder.lazy(25);

        expect(stream, isA<Stream<Map<String, dynamic>>>());
      });
    });
  });

  group('Phase 4: Advanced Pagination & Locking', () {
    group('simplePaginate', () {
      test('returns simple pagination result', () async {
        final result = await queryBuilder.simplePaginate(page: 1);

        expect(result, isA<Map<String, dynamic>>());
        expect(result, containsPair('data', anything));
        expect(result, containsPair('perPage', 15));
        expect(result, containsPair('currentPage', 1));
        expect(result, containsPair('hasMorePages', anything));
      });

      test('handles different page sizes', () async {
        final result = await queryBuilder.simplePaginate(perPage: 25, page: 2);

        expect(result['perPage'], equals(25));
        expect(result['currentPage'], equals(2));
      });
    });

    group('cursorPaginate', () {
      test('returns cursor pagination result without cursor', () async {
        final result = await queryBuilder.cursorPaginate(perPage: 20);

        expect(result, isA<Map<String, dynamic>>());
        expect(result, containsPair('data', anything));
        expect(result, containsPair('perPage', 20));
        expect(result, containsPair('nextCursor', anything));
        expect(result, containsPair('hasMore', anything));
      });

      test('uses custom cursor and column', () async {
        final result = await queryBuilder.cursorPaginate(
          perPage: 10,
          cursor: '100',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result, containsPair('previousCursor', '100'));
      });
    });

    group('sharedLock', () {
      test('adds FOR SHARE to query', () {
        queryBuilder.sharedLock();

        final sql = queryBuilder.toSql();
        expect(sql, contains('FOR SHARE'));
      });

      test('chains with other clauses', () {
        queryBuilder.where('active', '=', true).sharedLock();

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `active` = ?'));
        expect(sql, contains('FOR SHARE'));
      });
    });

    group('lockForUpdate', () {
      test('adds FOR UPDATE to query', () {
        queryBuilder.lockForUpdate();

        final sql = queryBuilder.toSql();
        expect(sql, contains('FOR UPDATE'));
      });

      test('chains with joins and where', () {
        queryBuilder
            .join('posts', 'users.id', '=', 'posts.user_id')
            .where('users.id', '=', 1)
            .lockForUpdate();

        final sql = queryBuilder.toSql();
        expect(sql, contains('INNER JOIN'));
        expect(sql, contains('WHERE'));
        expect(sql, contains('FOR UPDATE'));
      });
    });
  });

  group('Phase 5: Union & Subqueries', () {
    group('union', () {
      test('combines two queries with UNION', () {
        final query2 = MySQLQueryBuilder<Map<String, dynamic>>(
          mockConnection,
          'users',
        ).where('verified', '=', true);

        queryBuilder.where('role', '=', 'admin').union(query2);

        final sql = queryBuilder.toSql();
        expect(sql, contains('UNION'));
      });
    });

    group('unionAll', () {
      test('combines two queries with UNION ALL', () {
        final query2 = MySQLQueryBuilder<Map<String, dynamic>>(
          mockConnection,
          'users',
        ).where('status', '=', 'active');

        queryBuilder.where('status', '=', 'pending').unionAll(query2);

        final sql = queryBuilder.toSql();
        expect(sql, contains('UNION ALL'));
      });
    });

    group('whereInSubquery', () {
      test('builds WHERE IN with subquery', () {
        queryBuilder.whereInSubquery('user_id', (q) {
          return q.select(['id']).where('active', '=', true).toSql();
        });

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `user_id` IN'));
      });
    });

    group('whereExists', () {
      test('builds WHERE EXISTS with subquery', () {
        queryBuilder.whereExists((q) {
          return q
              .select(['1'])
              .where('posts.user_id', '=', 'users.id')
              .toSql();
        });

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE EXISTS'));
      });
    });

    group('whereNotExists', () {
      test('builds WHERE NOT EXISTS with subquery', () {
        queryBuilder.whereNotExists((q) {
          return q
              .select(['1'])
              .where('bans.user_id', '=', 'users.id')
              .toSql();
        });

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE NOT EXISTS'));
      });
    });
  });

  group('Phase 6: Full-Text Search', () {
    group('whereFullText', () {
      test('builds MATCH AGAINST with natural mode', () {
        queryBuilder.whereFullText(['title', 'content'], 'search terms');

        final sql = queryBuilder.toSql();
        expect(sql, contains('MATCH (`title`, `content`) AGAINST'));
        expect(sql, contains('IN NATURAL LANGUAGE MODE'));
      });

      test('builds MATCH AGAINST with boolean mode', () {
        queryBuilder.whereFullText(
          ['description'],
          '+required -excluded',
          mode: 'boolean',
        );

        final sql = queryBuilder.toSql();
        expect(sql, contains('MATCH (`description`) AGAINST'));
        expect(sql, contains('IN BOOLEAN MODE'));
      });

      test('builds MATCH AGAINST with query expansion', () {
        queryBuilder.whereFullText(
          ['article'],
          'database',
          mode: 'query_expansion',
        );

        final sql = queryBuilder.toSql();
        expect(sql, contains('MATCH (`article`) AGAINST'));
        expect(sql, contains('WITH QUERY EXPANSION'));
      });

      test('chains with other WHERE clauses', () {
        queryBuilder
            .whereFullText(['title', 'body'], 'search')
            .where('published', '=', true)
            .orderBy('created_at', direction: 'DESC');

        final sql = queryBuilder.toSql();
        expect(sql, contains('MATCH'));
        expect(sql, contains('AND `published` = ?'));
        expect(sql, contains('ORDER BY'));
      });
    });
  });

  group('Complex Combinations', () {
    test('combines JOINs, WHERE, pagination, and locking', () {
      queryBuilder
          .select(['users.*', 'posts.title'])
          .join('posts', 'users.id', '=', 'posts.user_id')
          .whereIn('users.role', ['admin', 'editor'])
          .whereNotNull('posts.published_at')
          .orderBy('posts.created_at', direction: 'DESC')
          .limit(20)
          .lockForUpdate();

      final sql = queryBuilder.toSql();
      expect(sql, contains('SELECT users.*, posts.title'));
      expect(sql, contains('INNER JOIN `posts`'));
      expect(sql, contains('WHERE `users.role` IN'));
      expect(sql, contains('AND `posts.published_at` IS NOT NULL'));
      expect(sql, contains('ORDER BY'));
      expect(sql, contains('LIMIT 20'));
      expect(sql, contains('FOR UPDATE'));
    });

    test('full-text search with JOINs and complex filters', () {
      queryBuilder
          .distinct()
          .select(['posts.*', 'users.name'])
          .join('users', 'posts.user_id', '=', 'users.id')
          .whereFullText(['posts.title', 'posts.content'], 'technology')
          .whereIn('posts.category_id', [1, 2, 3])
          .whereBetween('posts.created_at', '2024-01-01', '2024-12-31')
          .whereNotNull('posts.featured_image')
          .orderBy('posts.score', direction: 'DESC')
          .limit(50);

      final sql = queryBuilder.toSql();
      expect(sql, contains('SELECT DISTINCT posts.*, users.name'));
      expect(sql, contains('INNER JOIN `users`'));
      expect(sql, contains('MATCH'));
      expect(sql, contains('AND `posts.category_id` IN'));
      expect(sql, contains('AND `posts.created_at` BETWEEN'));
      expect(sql, contains('AND `posts.featured_image` IS NOT NULL'));
    });

    test('clone preserves all new features', () {
      queryBuilder
          .join('posts', 'users.id', '=', 'posts.user_id')
          .whereIn('status', ['active'])
          .sharedLock();

      final cloned = queryBuilder.clone();
      final originalSql = queryBuilder.toSql();
      final clonedSql = cloned.toSql();

      expect(clonedSql, equals(originalSql));
      expect(clonedSql, contains('INNER JOIN'));
      expect(clonedSql, contains('FOR SHARE'));
    });
  });

  group('SQL Structure Validation', () {
    test('correct ordering of all SQL clauses', () {
      queryBuilder
          .select(['id', 'name'])
          .distinct()
          .join('posts', 'users.id', '=', 'posts.user_id')
          .leftJoin('profiles', 'users.id', '=', 'profiles.user_id')
          .where('users.active', '=', true)
          .whereIn('users.role', ['admin'])
          .groupBy('users.id')
          .having('count', '>', 5)
          .orderBy('users.created_at', direction: 'DESC')
          .limit(10)
          .offset(20)
          .lockForUpdate();

      final sql = queryBuilder.toSql();

      // Verify correct clause ordering
      final selectIndex = sql.indexOf('SELECT');
      final joinIndex = sql.indexOf('JOIN');
      final whereIndex = sql.indexOf('WHERE');
      final groupIndex = sql.indexOf('GROUP BY');
      final havingIndex = sql.indexOf('HAVING');
      final orderIndex = sql.indexOf('ORDER BY');
      final limitIndex = sql.indexOf('LIMIT');
      final offsetIndex = sql.indexOf('OFFSET');
      final lockIndex = sql.indexOf('FOR UPDATE');

      expect(selectIndex, lessThan(joinIndex));
      expect(joinIndex, lessThan(whereIndex));
      expect(whereIndex, lessThan(groupIndex));
      expect(groupIndex, lessThan(havingIndex));
      expect(havingIndex, lessThan(orderIndex));
      expect(orderIndex, lessThan(limitIndex));
      expect(limitIndex, lessThan(offsetIndex));
      expect(offsetIndex, lessThan(lockIndex));
    });
  });
}

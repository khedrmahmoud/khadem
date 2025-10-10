import 'package:khadem/src/contracts/database/connection_interface.dart';
import 'package:khadem/src/contracts/database/database_response.dart';
import 'package:khadem/src/contracts/database/query_builder_interface.dart';
import 'package:khadem/src/core/database/database_drivers/mysql/mysql_query_builder.dart';
import 'package:test/test.dart';

// Simple mock connection for testing SQL generation only
class _MockConnection implements ConnectionInterface {
  @override
  Future<DatabaseResponse> execute(String query, [List<dynamic> bindings = const []]) async {
    return DatabaseResponse(data: [], affectedRows: 0);
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

/// Comprehensive tests for Phase 7 - Advanced Query Builder Features
/// 
/// Tests cover:
/// - OR WHERE variants (15+ methods)
/// - whereHas/whereDoesntHave for relationship queries
/// - Advanced subquery methods
/// - Column comparisons and date helpers
/// - Logical grouping (whereNested)
void main() {
  late ConnectionInterface connection;
  late MySQLQueryBuilder<Map<String, dynamic>> query;

  setUp(() {
    connection = _MockConnection();
    query = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'users');
  });

  group('OR WHERE Variants', () {
    test('orWhereIn adds OR IN clause', () {
      final sql = query
          .where('role', '=', 'admin')
          .orWhereIn('status', ['active', 'pending'])
          .toSql();

      expect(sql, contains('`role` = ?'));
      expect(sql, contains('OR `status` IN (?, ?)'));
    });

    test('orWhereIn as first clause behaves like whereIn', () {
      final sql = query.orWhereIn('id', [1, 2, 3]).toSql();

      expect(sql, contains('`id` IN (?, ?, ?)'));
      expect(sql, isNot(contains('OR')));
    });

    test('orWhereNotIn adds OR NOT IN clause', () {
      final sql = query
          .where('active', '=', true)
          .orWhereNotIn('id', [5, 10, 15])
          .toSql();

      expect(sql, contains('`active` = ?'));
      expect(sql, contains('OR `id` NOT IN (?, ?, ?)'));
    });

    test('orWhereNull adds OR IS NULL clause', () {
      final sql = query
          .where('active', '=', true)
          .orWhereNull('deleted_at')
          .toSql();

      expect(sql, contains('`active` = ?'));
      expect(sql, contains('OR `deleted_at` IS NULL'));
    });

    test('orWhereNotNull adds OR IS NOT NULL clause', () {
      final sql = query
          .whereNull('email_verified_at')
          .orWhereNotNull('phone_verified_at')
          .toSql();

      expect(sql, contains('`email_verified_at` IS NULL'));
      expect(sql, contains('OR `phone_verified_at` IS NOT NULL'));
    });

    test('orWhereBetween adds OR BETWEEN clause', () {
      final sql = query
          .where('age', '<', 18)
          .orWhereBetween('age', 65, 100)
          .toSql();

      expect(sql, contains('`age` < ?'));
      expect(sql, contains('OR `age` BETWEEN ? AND ?'));
    });

    test('orWhereNotBetween adds OR NOT BETWEEN clause', () {
      final sql = query
          .whereBetween('score', 0, 50)
          .orWhereNotBetween('score', 90, 100)
          .toSql();

      expect(sql, contains('`score` BETWEEN ? AND ?'));
      expect(sql, contains('OR `score` NOT BETWEEN ? AND ?'));
    });

    test('orWhereLike adds OR LIKE clause', () {
      final sql = query
          .whereLike('name', 'John%')
          .orWhereLike('email', '%@gmail.com')
          .toSql();

      expect(sql, contains('`name` LIKE ?'));
      expect(sql, contains('OR `email` LIKE ?'));
    });

    test('orWhereNotLike adds OR NOT LIKE clause', () {
      final sql = query
          .whereNotLike('name', '%admin%')
          .orWhereNotLike('email', '%test%')
          .toSql();

      expect(sql, contains('`name` NOT LIKE ?'));
      expect(sql, contains('OR `email` NOT LIKE ?'));
    });

    test('orWhereDate adds OR DATE clause', () {
      final sql = query
          .whereDate('created_at', '2024-01-01')
          .orWhereDate('updated_at', '2024-12-31')
          .toSql();

      expect(sql, contains('DATE(`created_at`) = ?'));
      expect(sql, contains('OR DATE(`updated_at`) = ?'));
    });

    test('orWhereTime adds OR TIME clause', () {
      final sql = query
          .whereTime('start_time', '09:00:00')
          .orWhereTime('end_time', '17:00:00')
          .toSql();

      expect(sql, contains('TIME(`start_time`) = ?'));
      expect(sql, contains('OR TIME(`end_time`) = ?'));
    });

    test('orWhereYear adds OR YEAR clause', () {
      final sql = query
          .whereYear('created_at', 2023)
          .orWhereYear('created_at', 2024)
          .toSql();

      expect(sql, contains('YEAR(`created_at`) = ?'));
      expect(sql, contains('OR YEAR(`created_at`) = ?'));
    });

    test('orWhereMonth adds OR MONTH clause', () {
      final sql = query
          .whereMonth('birthday', 1)
          .orWhereMonth('birthday', 12)
          .toSql();

      expect(sql, contains('MONTH(`birthday`) = ?'));
      expect(sql, contains('OR MONTH(`birthday`) = ?'));
    });

    test('orWhereDay adds OR DAY clause', () {
      final sql = query
          .whereDay('created_at', 1)
          .orWhereDay('created_at', 15)
          .toSql();

      expect(sql, contains('DAY(`created_at`) = ?'));
      expect(sql, contains('OR DAY(`created_at`) = ?'));
    });

    test('orWhereColumn adds OR column comparison', () {
      final sql = query
          .whereColumn('first_name', '=', 'last_name')
          .orWhereColumn('created_at', '>', 'updated_at')
          .toSql();

      expect(sql, contains('`first_name` = `last_name`'));
      expect(sql, contains('OR `created_at` > `updated_at`'));
    });

    test('orWhereJsonContains adds OR JSON_CONTAINS clause', () {
      final sql = query
          .whereJsonContains('tags', 'tutorial')
          .orWhereJsonContains('tags', 'advanced')
          .toSql();

      expect(sql, contains('JSON_CONTAINS(`tags`, ?)'));
      expect(sql, contains('OR JSON_CONTAINS(`tags`, ?)'));
    });

    test('multiple OR clauses chain correctly', () {
      final sql = query
          .where('role', '=', 'admin')
          .orWhere('role', '=', 'editor')
          .orWhereIn('status', ['active', 'verified'])
          .orWhereNotNull('premium_until')
          .toSql();

      expect(sql, contains('`role` = ?'));
      expect(sql, contains('OR `role` = ?'));
      expect(sql, contains('OR `status` IN (?, ?)'));
      expect(sql, contains('OR `premium_until` IS NOT NULL'));
    });
  });

  group('whereHas - Relationship Existence Queries', () {
    test('whereHas adds relationship existence check', () {
      final sql = query.whereHas('posts').toSql();

      expect(sql, contains('SELECT COUNT(*)'));
      expect(sql, contains('FROM `posts`'));
      expect(sql, contains('>= ?'));
    });

    test('whereHas with callback applies constraints', () {
      final sql = query.whereHas('posts', (q) {
        q.where('published', '=', true);
      }).toSql();

      expect(sql, contains('SELECT COUNT(*)'));
      expect(sql, contains('FROM `posts`'));
      expect(sql, contains('`published` = ?'));
    });

    test('whereHas with custom count operator', () {
      final sql = query.whereHas('posts', null, '>', 5).toSql();

      expect(sql, contains('SELECT COUNT(*)'));
      expect(sql, contains('> ?'));
    });

    test('orWhereHas adds OR relationship check', () {
      final sql = query
          .where('active', '=', true)
          .orWhereHas('posts', (q) {
            q.where('featured', '=', true);
          })
          .toSql();

      expect(sql, contains('`active` = ?'));
      expect(sql, contains('OR'));
      expect(sql, contains('SELECT COUNT(*)'));
      expect(sql, contains('`featured` = ?'));
    });

    test('whereDoesntHave checks relationship absence', () {
      final sql = query.whereDoesntHave('posts').toSql();

      expect(sql, contains('NOT EXISTS'));
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('FROM `posts`'));
    });

    test('whereDoesntHave with callback', () {
      final sql = query.whereDoesntHave('posts', (q) {
        q.where('draft', '=', true);
      }).toSql();

      expect(sql, contains('NOT EXISTS'));
      expect(sql, contains('`draft` = ?'));
    });

    test('orWhereDoesntHave adds OR NOT EXISTS', () {
      final sql = query
          .where('verified', '=', false)
          .orWhereDoesntHave('violations')
          .toSql();

      expect(sql, contains('`verified` = ?'));
      expect(sql, contains('OR NOT EXISTS'));
    });

    test('has is shorthand for whereHas', () {
      final sql1 = query.has('posts').toSql();
      final sql2 = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'users')
          .whereHas('posts')
          .toSql();

      expect(sql1, equals(sql2));
    });

    test('doesntHave is shorthand for whereDoesntHave', () {
      final sql1 = query.doesntHave('posts').toSql();
      final sql2 = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'users')
          .whereDoesntHave('posts')
          .toSql();

      expect(sql1, equals(sql2));
    });

    test('complex whereHas with multiple constraints', () {
      final sql = query.whereHas('posts', (q) {
        q.where('published', '=', true)
            .where('views', '>', 1000)
            .whereNotNull('featured_image');
      }, '>=', 3,).toSql();

      expect(sql, contains('SELECT COUNT(*)'));
      expect(sql, contains('`published` = ?'));
      expect(sql, contains('`views` > ?'));
      expect(sql, contains('`featured_image` IS NOT NULL'));
      expect(sql, contains('>= ?'));
    });
  });

  group('Advanced Column Comparisons', () {
    test('whereBetweenColumns compares column against two other columns', () {
      final sql = query
          .whereBetweenColumns('salary', 'min_salary', 'max_salary')
          .toSql();

      expect(sql, contains('`salary` BETWEEN `min_salary` AND `max_salary`'));
    });

    test('whereNotBetweenColumns adds NOT BETWEEN columns clause', () {
      final sql = query
          .whereNotBetweenColumns('age', 'min_age', 'max_age')
          .toSql();

      expect(sql, contains('`age` NOT BETWEEN `min_age` AND `max_age`'));
    });
  });

  group('Advanced Date Comparisons', () {
    test('wherePast filters dates in the past', () {
      final sql = query.wherePast('expires_at').toSql();

      expect(sql, contains('`expires_at` < NOW()'));
    });

    test('whereFuture filters dates in the future', () {
      final sql = query.whereFuture('scheduled_at').toSql();

      expect(sql, contains('`scheduled_at` > NOW()'));
    });

    test('whereToday filters dates for today', () {
      final sql = query.whereToday('created_at').toSql();

      expect(sql, contains('DATE(`created_at`) = CURDATE()'));
    });

    test('whereBeforeToday filters dates before today', () {
      final sql = query.whereBeforeToday('due_date').toSql();

      expect(sql, contains('DATE(`due_date`) < CURDATE()'));
    });

    test('whereAfterToday filters dates after today', () {
      final sql = query.whereAfterToday('start_date').toSql();

      expect(sql, contains('DATE(`start_date`) > CURDATE()'));
    });

    test('date comparisons can be combined', () {
      final sql = query
          .wherePast('expires_at')
          .whereFuture('renew_at') // Use whereFuture and chain with orWhere if needed
          .toSql();

      expect(sql, contains('`expires_at` < NOW()'));
      expect(sql, contains('`renew_at` > NOW()'));
    });
  });

  group('Subquery Methods', () {
    test('fromSub uses subquery as FROM clause', () {
      final subquery = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'users')
          .where('active', '=', true)
          .select(['id', 'name']);

      final sql = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'temp')
          .fromSub(subquery, 'active_users')
          .select(['name'])
          .toSql();

      expect(sql, contains('FROM ('));
      expect(sql, contains('SELECT id, name FROM `users`'));
      expect(sql, contains('WHERE `active` = ?'));
      expect(sql, contains(') AS `active_users`'));
    });

    test('fromRaw uses raw SQL as FROM clause', () {
      final sql = query
          .fromRaw('(SELECT * FROM users WHERE age > 18) AS adults')
          .select(['name'])
          .toSql();

      expect(sql, contains('FROM (SELECT * FROM users WHERE age > 18) AS adults'));
    });

    test('selectSub adds subquery to SELECT clause', () {
      final subquery = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'posts')
          .where('posts.user_id', '=', 'users.id')
          .select(['COUNT(*)']);

      final sql = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'users')
          .select(['id', 'name'])
          .selectSub(subquery, 'posts_count')
          .toSql();

      expect(sql, contains('SELECT id, name, (SELECT COUNT(*) FROM `posts`'));
      expect(sql, contains(') AS `posts_count`'));
    });

    test('multiple selectSub clauses', () {
      final postsCount = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'posts')
          .select(['COUNT(*)']);
      
      final commentsCount = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'comments')
          .select(['COUNT(*)']);

      final sql = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'users')
          .select(['id'])
          .selectSub(postsCount, 'posts_count')
          .selectSub(commentsCount, 'comments_count')
          .toSql();

      expect(sql, contains('(SELECT COUNT(*) FROM `posts`) AS `posts_count`'));
      expect(sql, contains('(SELECT COUNT(*) FROM `comments`) AS `comments_count`'));
    });
  });

  group('Logical Grouping', () {
    test('whereNested groups conditions in parentheses', () {
      final sql = query
          .where('active', '=', true)
          .whereNested((q) {
            q.where('role', '=', 'admin').orWhere('role', '=', 'editor');
          })
          .toSql();

      expect(sql, contains('`active` = ?'));
      expect(sql, contains('(`role` = ? OR `role` = ?)'));
    });

    test('orWhereNested adds OR grouped conditions', () {
      final sql = query
          .where('status', '=', 'published')
          .orWhereNested((q) {
            q.where('draft', '=', true).where('owner_id', '=', 1);
          })
          .toSql();

      expect(sql, contains('`status` = ?'));
      expect(sql, contains('OR (`draft` = ? AND `owner_id` = ?)'));
    });

    test('nested groups can be deeply nested', () {
      final sql = query
          .where('active', '=', true)
          .whereNested((q) {
            q.where('role', '=', 'admin')
                .orWhereNested((q2) {
                  q2.where('role', '=', 'editor')
                      .where('verified', '=', true);
                });
          })
          .toSql();

      expect(sql, contains('`active` = ?'));
      expect(sql, contains('(`role` = ?'));
      expect(sql, contains('OR (`role` = ? AND `verified` = ?'));
    });

    test('whereNested as first clause works correctly', () {
      final sql = query.whereNested((q) {
        q.where('a', '=', 1).orWhere('b', '=', 2);
      }).toSql();

      expect(sql, contains('WHERE (`a` = ? OR `b` = ?)'));
    });
  });

  group('Complex Combinations', () {
    test('OR variants + whereHas + nested conditions', () {
      final sql = query
          .where('active', '=', true)
          .orWhereNested((q) {
            q.where('role', '=', 'admin')
                .whereHas('permissions', (pq) {
                  pq.where('name', '=', 'manage_users');
                });
          })
          .orWhereIn('id', [1, 2, 3])
          .toSql();

      expect(sql, contains('`active` = ?'));
      expect(sql, contains('OR (`role` = ?'));
      expect(sql, contains('SELECT COUNT(*)'));
      expect(sql, contains('OR `id` IN (?, ?, ?)'));
    });

    test('date helpers + OR variants + subqueries', () {
      final sql = query
          .wherePast('trial_ends_at')
          .orWhereNested((q) {
            q.whereFuture('premium_until')
                .whereHas('subscriptions', (sq) {
                  sq.where('plan', '=', 'pro');
                });
          })
          .toSql();

      expect(sql, contains('`trial_ends_at` < NOW()'));
      expect(sql, contains('OR (`premium_until` > NOW()'));
      expect(sql, contains('SELECT COUNT(*)'));
    });

    test('all features combined in realistic query', () {
      final sql = query
          .select(['id', 'name', 'email'])
          .distinct()
          .whereNested((q) {
            q.where('verified', '=', true)
                .orWhereHas('verifications', (vq) {
                  vq.where('method', '=', 'email')
                      .whereFuture('expires_at');
                });
          })
          .whereBetweenColumns('salary', 'min_salary', 'max_salary')
          .orWhereNested((q) {
            q.whereToday('created_at')
                .whereDoesntHave('violations');
          })
          .orWhereIn('role', ['admin', 'moderator'])
          .orderBy('created_at', direction: 'DESC')
          .limit(20)
          .toSql();

      expect(sql, contains('SELECT DISTINCT'));
      expect(sql, contains('(`verified` = ?'));
      expect(sql, contains('SELECT COUNT(*)'));
      expect(sql, contains('BETWEEN `min_salary` AND `max_salary`'));
      expect(sql, contains('DATE(`created_at`) = CURDATE()'));
      expect(sql, contains('NOT EXISTS'));
      expect(sql, contains('OR `role` IN (?, ?)'));
      expect(sql, contains('ORDER BY'));
      expect(sql, contains('LIMIT 20'));
    });
  });

  group('Clone Preserves New Fields', () {
    test('clone preserves fromSubquery and selectSubqueries', () {
      final subquery = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'active_users')
          .where('active', '=', true);

      final original = MySQLQueryBuilder<Map<String, dynamic>>(connection, 'users')
          .fromSub(subquery, 'au')
          .selectSub(subquery, 'count');

      final cloned = original.clone();
      final sql1 = original.toSql();
      final sql2 = cloned.toSql();

      expect(sql2, equals(sql1));
      expect(sql2, contains('FROM ('));
      expect(sql2, contains(') AS `au`'));
    });

    test('clone with all new features', () {
      final original = query
          .whereHas('posts')
          .orWhereIn('status', ['active'])
          .whereNested((q) {
            q.wherePast('expires_at');
          })
          .whereBetweenColumns('a', 'b', 'c');

      final cloned = original.clone();
      final sql1 = original.toSql();
      final sql2 = cloned.toSql();

      expect(sql2, equals(sql1));
    });
  });

  group('Edge Cases and Error Handling', () {
    test('orWhere methods as first clause fallback to regular WHERE', () {
      final sql = query
          .orWhereIn('id', [1, 2])
          .toSql();

      // When first clause is OR, it should behave like normal WHERE
      expect(sql, contains('WHERE `id` IN (?, ?)'));
      expect(sql, isNot(contains('OR `id`')));
    });
    
    test('orWhere methods work correctly after a WHERE clause', () {
      final sql = query
          .whereIn('id', [1, 2])
          .orWhereNull('deleted_at')
          .toSql();

      expect(sql, contains('WHERE `id` IN (?, ?) OR `deleted_at` IS NULL'));
    });

    test('empty whereNested does not add clause', () {
      final sql = query
          .where('active', '=', true)
          .whereNested((q) {
            // Empty callback
          })
          .toSql();

      expect(sql, equals('SELECT * FROM `users` WHERE `active` = ?'));
    });

    test('whereHas with empty relation table', () {
      // This should work - it will query the relation table
      final sql = query.whereHas('posts').toSql();

      expect(sql, contains('FROM `posts`'));
    });
  });
}

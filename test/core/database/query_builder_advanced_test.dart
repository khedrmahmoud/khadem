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

  group('Advanced WHERE Clauses', () {
    group('whereIn', () {
      test('builds correct SQL with multiple values', () {
        queryBuilder.whereIn('status', ['active', 'pending', 'approved']);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `status` IN (?, ?, ?)'));
      });

      test('handles empty array gracefully', () {
        queryBuilder.whereIn('status', []);

        final sql = queryBuilder.toSql();
        expect(sql, isNot(contains('IN')));
      });

      test('chains with other WHERE clauses', () {
        queryBuilder
            .where('active', '=', true)
            .whereIn('role', ['admin', 'editor']);

        final sql = queryBuilder.toSql();
        expect(sql, contains('`active` = ?'));
        expect(sql, contains('AND `role` IN (?, ?)'));
      });

      test('works with numeric values', () {
        queryBuilder.whereIn('id', [1, 2, 3, 4, 5]);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `id` IN (?, ?, ?, ?, ?)'));
      });
    });

    group('whereNotIn', () {
      test('builds correct SQL with NOT IN', () {
        queryBuilder.whereNotIn('status', ['banned', 'deleted']);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `status` NOT IN (?, ?)'));
      });

      test('handles empty array gracefully', () {
        queryBuilder.whereNotIn('status', []);

        final sql = queryBuilder.toSql();
        expect(sql, isNot(contains('NOT IN')));
      });
    });

    group('whereNull', () {
      test('builds correct SQL for NULL check', () {
        queryBuilder.whereNull('deleted_at');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `deleted_at` IS NULL'));
      });

      test('chains with other clauses', () {
        queryBuilder.where('active', '=', true).whereNull('deleted_at');

        final sql = queryBuilder.toSql();
        expect(sql, contains('`active` = ? AND `deleted_at` IS NULL'));
      });
    });

    group('whereNotNull', () {
      test('builds correct SQL for NOT NULL check', () {
        queryBuilder.whereNotNull('email_verified_at');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `email_verified_at` IS NOT NULL'));
      });
    });

    group('whereBetween', () {
      test('builds correct SQL for BETWEEN with numbers', () {
        queryBuilder.whereBetween('age', 18, 65);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `age` BETWEEN ? AND ?'));
      });

      test('builds correct SQL for BETWEEN with dates', () {
        queryBuilder.whereBetween(
          'created_at',
          '2024-01-01',
          '2024-12-31',
        );

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `created_at` BETWEEN ? AND ?'));
      });

      test('chains with other WHERE clauses', () {
        queryBuilder
            .where('active', '=', true)
            .whereBetween('price', 100, 500);

        final sql = queryBuilder.toSql();
        expect(sql, contains('`active` = ? AND `price` BETWEEN ? AND ?'));
      });
    });

    group('whereNotBetween', () {
      test('builds correct SQL for NOT BETWEEN', () {
        queryBuilder.whereNotBetween('price', 100, 500);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `price` NOT BETWEEN ? AND ?'));
      });
    });

    group('whereLike', () {
      test('builds correct SQL for LIKE pattern', () {
        queryBuilder.whereLike('name', '%John%');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `name` LIKE ?'));
      });

      test('handles different patterns', () {
        queryBuilder.whereLike('email', 'admin@%');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `email` LIKE ?'));
      });

      test('chains multiple LIKE clauses', () {
        queryBuilder.whereLike('name', '%John%').whereLike('email', '%@gmail.com');

        final sql = queryBuilder.toSql();
        expect(sql, contains('`name` LIKE ? AND `email` LIKE ?'));
      });
    });

    group('whereNotLike', () {
      test('builds correct SQL for NOT LIKE', () {
        queryBuilder.whereNotLike('email', '%spam%');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `email` NOT LIKE ?'));
      });
    });

    group('whereDate', () {
      test('builds correct SQL for DATE comparison', () {
        queryBuilder.whereDate('created_at', '2024-01-01');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE DATE(`created_at`) = ?'));
      });

      test('chains with other clauses', () {
        queryBuilder
            .whereDate('created_at', '2024-01-01')
            .where('active', '=', true);

        final sql = queryBuilder.toSql();
        expect(
          sql,
          contains('DATE(`created_at`) = ? AND `active` = ?'),
        );
      });
    });

    group('whereTime', () {
      test('builds correct SQL for TIME comparison', () {
        queryBuilder.whereTime('created_at', '14:30:00');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE TIME(`created_at`) = ?'));
      });
    });

    group('whereYear', () {
      test('builds correct SQL for YEAR comparison', () {
        queryBuilder.whereYear('created_at', 2024);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE YEAR(`created_at`) = ?'));
      });
    });

    group('whereMonth', () {
      test('builds correct SQL for MONTH comparison', () {
        queryBuilder.whereMonth('created_at', 12);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE MONTH(`created_at`) = ?'));
      });
    });

    group('whereDay', () {
      test('builds correct SQL for DAY comparison', () {
        queryBuilder.whereDay('created_at', 25);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE DAY(`created_at`) = ?'));
      });
    });

    group('whereColumn', () {
      test('builds correct SQL for column comparison', () {
        queryBuilder.whereColumn('first_name', '=', 'last_name');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `first_name` = `last_name`'));
      });

      test('supports different operators', () {
        queryBuilder.whereColumn('updated_at', '>', 'created_at');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE `updated_at` > `created_at`'));
      });

      test('chains with other WHERE clauses', () {
        queryBuilder
            .where('active', '=', true)
            .whereColumn('end_date', '>', 'start_date');

        final sql = queryBuilder.toSql();
        expect(sql, contains('`active` = ? AND `end_date` > `start_date`'));
      });
    });
  });

  group('JSON Operations', () {
    group('whereJsonContains', () {
      test('builds correct SQL for JSON_CONTAINS without path', () {
        queryBuilder.whereJsonContains('preferences', 'en');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE JSON_CONTAINS(`preferences`, ?)'));
      });

      test('builds correct SQL for JSON_CONTAINS with path', () {
        queryBuilder.whereJsonContains('preferences', 'en', 'languages');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE JSON_CONTAINS(`preferences`, ?, ?)'));
      });

      test('handles object values', () {
        queryBuilder.whereJsonContains('metadata', {'key': 'value'});

        final sql = queryBuilder.toSql();
        expect(sql, contains('JSON_CONTAINS(`metadata`, ?)'));
      });
    });

    group('whereJsonDoesntContain', () {
      test('builds correct SQL for NOT JSON_CONTAINS', () {
        queryBuilder.whereJsonDoesntContain('preferences', 'premium');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE NOT JSON_CONTAINS(`preferences`, ?)'));
      });

      test('builds correct SQL with path', () {
        queryBuilder.whereJsonDoesntContain(
          'options',
          'disabled',
          'features',
        );

        final sql = queryBuilder.toSql();
        expect(sql, contains('NOT JSON_CONTAINS(`options`, ?, ?)'));
      });
    });

    group('whereJsonLength', () {
      test('builds correct SQL for JSON_LENGTH without path', () {
        queryBuilder.whereJsonLength('tags', '>', 3);

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE JSON_LENGTH(`tags`) > ?'));
      });

      test('builds correct SQL for JSON_LENGTH with path', () {
        queryBuilder.whereJsonLength('metadata', '=', 5, 'items');

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE JSON_LENGTH(`metadata`, ?) = ?'));
      });

      test('supports different operators', () {
        queryBuilder.whereJsonLength('options', '>=', 2);

        final sql = queryBuilder.toSql();
        expect(sql, contains('JSON_LENGTH(`options`) >= ?'));
      });
    });

    group('whereJsonContainsKey', () {
      test('builds correct SQL for JSON_CONTAINS_PATH', () {
        queryBuilder.whereJsonContainsKey('metadata', 'settings');

        final sql = queryBuilder.toSql();
        expect(
          sql,
          contains("WHERE JSON_CONTAINS_PATH(`metadata`, 'one', ?)"),
        );
      });

      test('handles nested paths', () {
        queryBuilder.whereJsonContainsKey('preferences', 'user.theme');

        final sql = queryBuilder.toSql();
        expect(sql, contains("JSON_CONTAINS_PATH(`preferences`, 'one', ?)"));
      });
    });
  });

  group('Advanced Query Helpers', () {
    group('whereAny', () {
      test('builds correct SQL for OR conditions across columns', () {
        queryBuilder.whereAny(['name', 'email', 'phone'], 'LIKE', '%search%');

        final sql = queryBuilder.toSql();
        expect(
          sql,
          contains(
            'WHERE (`name` LIKE ? OR `email` LIKE ? OR `phone` LIKE ?)',
          ),
        );
      });

      test('handles empty column list gracefully', () {
        queryBuilder.whereAny([], '=', 'value');

        final sql = queryBuilder.toSql();
        expect(sql, isNot(contains('OR')));
      });

      test('chains with other WHERE clauses', () {
        queryBuilder
            .where('active', '=', true)
            .whereAny(['name', 'email'], 'LIKE', '%john%');

        final sql = queryBuilder.toSql();
        expect(sql, contains('`active` = ?'));
        expect(sql, contains('AND (`name` LIKE ? OR `email` LIKE ?)'));
      });
    });

    group('whereAll', () {
      test('builds correct SQL for multiple AND conditions', () {
        queryBuilder.whereAll({
          'status': 'active',
          'verified': true,
          'role': 'admin',
        });

        final sql = queryBuilder.toSql();
        expect(sql, contains('`status` = ?'));
        expect(sql, contains('AND `verified` = ?'));
        expect(sql, contains('AND `role` = ?'));
      });

      test('handles empty map gracefully', () {
        queryBuilder.whereAll({});

        final sql = queryBuilder.toSql();
        // Should not add any WHERE clauses
        expect(sql, equals('SELECT * FROM `users`'));
      });
    });

    group('whereNone', () {
      test('builds correct SQL for NOT conditions', () {
        queryBuilder.whereNone({
          'banned': true,
          'deleted': true,
        });

        final sql = queryBuilder.toSql();
        expect(sql, contains('WHERE NOT (`banned` = ? OR `deleted` = ?)'));
      });

      test('handles empty map gracefully', () {
        queryBuilder.whereNone({});

        final sql = queryBuilder.toSql();
        expect(sql, isNot(contains('NOT')));
      });
    });

    group('latest', () {
      test('adds ORDER BY DESC with default column', () {
        queryBuilder.latest();

        final sql = queryBuilder.toSql();
        expect(sql, contains('ORDER BY `created_at` DESC'));
      });

      test('accepts custom column', () {
        queryBuilder.latest('updated_at');

        final sql = queryBuilder.toSql();
        expect(sql, contains('ORDER BY `updated_at` DESC'));
      });
    });

    group('oldest', () {
      test('adds ORDER BY ASC with default column', () {
        queryBuilder.oldest();

        final sql = queryBuilder.toSql();
        expect(sql, contains('ORDER BY `created_at` ASC'));
      });

      test('accepts custom column', () {
        queryBuilder.oldest('registered_at');

        final sql = queryBuilder.toSql();
        expect(sql, contains('ORDER BY `registered_at` ASC'));
      });
    });

    group('inRandomOrder', () {
      test('adds ORDER BY RAND()', () {
        queryBuilder.inRandomOrder();

        final sql = queryBuilder.toSql();
        expect(sql, contains('ORDER BY RAND()'));
      });
    });

    group('distinct', () {
      test('adds DISTINCT to SELECT', () {
        queryBuilder.distinct();

        final sql = queryBuilder.toSql();
        expect(sql, contains('SELECT DISTINCT'));
      });

      test('works with specific columns', () {
        queryBuilder.select(['email']).distinct();

        final sql = queryBuilder.toSql();
        expect(sql, contains('SELECT DISTINCT email FROM'));
      });
    });

    group('addSelect', () {
      test('adds columns to existing select', () {
        queryBuilder.select(['id', 'name']).addSelect(['email', 'phone']);

        final sql = queryBuilder.toSql();
        expect(sql, contains('SELECT id, name, email, phone FROM'));
      });

      test('replaces * with columns when adding', () {
        queryBuilder.addSelect(['email']);

        final sql = queryBuilder.toSql();
        expect(sql, contains('SELECT email FROM'));
        expect(sql, isNot(contains('*')));
      });
    });
  });

  group('Complex Query Combinations', () {
    test('chains multiple advanced WHERE clauses', () {
      queryBuilder
          .whereIn('status', ['active', 'pending'])
          .whereNotNull('email_verified_at')
          .whereBetween('age', 18, 65)
          .whereLike('name', '%John%')
          .whereDate('created_at', '2024-01-01');

      final sql = queryBuilder.toSql();
      expect(sql, contains('`status` IN (?, ?)'));
      expect(sql, contains('AND `email_verified_at` IS NOT NULL'));
      expect(sql, contains('AND `age` BETWEEN ? AND ?'));
      expect(sql, contains('AND `name` LIKE ?'));
      expect(sql, contains('AND DATE(`created_at`) = ?'));
    });

    test('combines JSON operations with regular WHERE', () {
      queryBuilder
          .where('active', '=', true)
          .whereJsonContains('preferences', 'en', 'languages')
          .whereJsonLength('tags', '>', 3);

      final sql = queryBuilder.toSql();
      expect(sql, contains('`active` = ?'));
      expect(sql, contains('AND JSON_CONTAINS(`preferences`, ?, ?)'));
      expect(sql, contains('AND JSON_LENGTH(`tags`) > ?'));
    });

    test('uses helpers with WHERE and ordering', () {
      queryBuilder
          .whereIn('role', ['admin', 'editor'])
          .whereNotNull('last_login_at')
          .latest('last_login_at')
          .limit(10);

      final sql = queryBuilder.toSql();
      expect(sql, contains('WHERE `role` IN (?, ?)'));
      expect(sql, contains('AND `last_login_at` IS NOT NULL'));
      expect(sql, contains('ORDER BY `last_login_at` DESC'));
      expect(sql, contains('LIMIT 10'));
    });

    test('complex search with whereAny and other filters', () {
      queryBuilder
          .whereAny(['name', 'email', 'username'], 'LIKE', '%search%')
          .whereIn('status', ['active', 'verified'])
          .whereNotIn('role', ['banned', 'guest'])
          .distinct()
          .orderBy('score', direction: 'DESC');

      final sql = queryBuilder.toSql();
      expect(sql, contains('SELECT DISTINCT'));
      expect(
        sql,
        contains('(`name` LIKE ? OR `email` LIKE ? OR `username` LIKE ?)'),
      );
      expect(sql, contains('AND `status` IN (?, ?)'));
      expect(sql, contains('AND `role` NOT IN (?, ?)'));
      expect(sql, contains('ORDER BY `score` DESC'));
    });
  });

  group('Clone Functionality', () {
    test('clone preserves all advanced query state', () {
      queryBuilder
          .whereIn('status', ['active'])
          .whereNull('deleted_at')
          .distinct()
          .latest();

      final cloned = queryBuilder.clone();
      final originalSql = queryBuilder.toSql();
      final clonedSql = cloned.toSql();

      expect(clonedSql, equals(originalSql));
    });

    test('clone modifications do not affect original', () {
      queryBuilder.where('active', '=', true);

      final cloned = queryBuilder.clone();
      cloned.whereIn('role', ['admin', 'editor']);

      final originalSql = queryBuilder.toSql();
      final clonedSql = cloned.toSql();

      expect(originalSql, isNot(contains('IN')));
      expect(clonedSql, contains('IN'));
    });
  });

  group('Edge Cases', () {
    test('handles special characters in LIKE pattern', () {
      queryBuilder.whereLike('name', "%O'Brien%");

      final sql = queryBuilder.toSql();
      expect(sql, contains('LIKE ?'));
    });

    test('handles single value in whereIn', () {
      queryBuilder.whereIn('id', [1]);

      final sql = queryBuilder.toSql();
      expect(sql, contains('WHERE `id` IN (?)'));
    });

    test('chains whereNull with orWhere correctly', () {
      queryBuilder.whereNull('deleted_at').orWhere('active', '=', false);

      final sql = queryBuilder.toSql();
      expect(sql, contains('`deleted_at` IS NULL'));
      expect(sql, contains('OR `active` = ?'));
    });

    test('multiple date-based WHERE clauses', () {
      queryBuilder
          .whereYear('created_at', 2024)
          .whereMonth('created_at', 12)
          .whereDay('created_at', 25);

      final sql = queryBuilder.toSql();
      expect(sql, contains('YEAR(`created_at`) = ?'));
      expect(sql, contains('AND MONTH(`created_at`) = ?'));
      expect(sql, contains('AND DAY(`created_at`) = ?'));
    });
  });

  group('SQL Generation Accuracy', () {
    test('generates valid SQL with all features combined', () {
      queryBuilder
          .select(['id', 'name', 'email', 'created_at'])
          .distinct()
          .whereIn('status', ['active', 'pending'])
          .whereNotNull('email_verified_at')
          .whereBetween('age', 18, 65)
          .whereDate('created_at', '2024-01-01')
          .whereJsonContains('preferences', 'en', 'languages')
          .latest('created_at')
          .limit(20)
          .offset(0);

      final sql = queryBuilder.toSql();

      // Verify SQL structure
      expect(sql, startsWith('SELECT DISTINCT id, name, email, created_at'));
      expect(sql, contains('FROM `users`'));
      expect(sql, contains('WHERE'));
      expect(sql, contains('ORDER BY `created_at` DESC'));
      expect(sql, contains('LIMIT 20'));
      expect(sql, contains('OFFSET 0'));
    });
  });
}

import 'package:khadem/src/core/database/database_drivers/mysql/mysql_schema_builder.dart';
import 'package:test/test.dart';

void main() {
  group('MySQLSchemaBuilder', () {
    late MySQLSchemaBuilder builder;

    setUp(() {
      builder = MySQLSchemaBuilder();
    });

    test('creates basic table with id and string', () {
      builder.createIfNotExists('users', (table) {
        table.id();
        table.string('name');
        table.string('email').unique();
        table.timestamps();
      });

      final queries = builder.queries;
      expect(queries.length, 1);
      final sql = queries.first;

      expect(sql, contains('CREATE TABLE IF NOT EXISTS `users`'));
      expect(
        sql,
        contains('`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY'),
      );
      expect(sql, contains('`name` VARCHAR(255) NOT NULL'));
      expect(sql, contains('`email` VARCHAR(255) NOT NULL UNIQUE'));
      expect(sql, contains('`created_at` TIMESTAMP NOT NULL'));
      expect(sql, contains('`updated_at` TIMESTAMP NOT NULL'));
    });

    test('handles nullable and default values', () {
      builder.createIfNotExists('posts', (table) {
        table.id();
        table.string('title').nullable();
        table.boolean('is_published').defaultsTo(false);
        table.integer('views').defaultsTo(0);
        table
            .timestamp('published_at')
            .nullable()
            .defaultRaw('CURRENT_TIMESTAMP');
      });

      final sql = builder.queries.first;

      expect(sql, contains('`title` VARCHAR(255) NULL'));
      expect(sql, contains('`is_published` TINYINT(1) NOT NULL DEFAULT 0'));
      expect(sql, contains('`views` INT NOT NULL DEFAULT 0'));
      expect(
        sql,
        contains('`published_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP'),
      );
    });

    test('handles text', () {
      builder.createIfNotExists('articles', (table) {
        table.id();
        table.text('content');
      });

      final sql = builder.queries.first;
      expect(sql, contains('`content` TEXT NOT NULL'));
    });

    test('handles foreign keys', () {
      builder.createIfNotExists('comments', (table) {
        table.id();
        table.foreignId('user_id').foreign('users').onDelete('cascade');
        table.text('body');
      });

      final sql = builder.queries.first;
      expect(sql, contains('`user_id` BIGINT UNSIGNED NOT NULL'));
      expect(
        sql,
        contains(
          'CONSTRAINT `comments_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE',
        ),
      );
    });

    test('handles enums', () {
      builder.createIfNotExists('orders', (table) {
        table.id();
        table
            .enumColumn('status', ['pending', 'completed', 'failed'])
            .defaultsTo('pending');
      });

      final sql = builder.queries.first;
      expect(
        sql,
        contains(
          "`status` ENUM('pending', 'completed', 'failed') NOT NULL DEFAULT 'pending'",
        ),
      );
    });

    test('handles charset and collation', () {
      builder.createIfNotExists('utf8_table', (table) {
        table.id();
        table.string('name').charset('utf8mb4').collation('utf8mb4_unicode_ci');
      });

      final sql = builder.queries.first;
      expect(
        sql,
        contains(
          "`name` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL",
        ),
      );
    });
  });
}

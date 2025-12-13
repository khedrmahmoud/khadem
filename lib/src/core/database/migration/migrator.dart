import 'dart:io';

import '../../../application/khadem.dart';
import '../../../contracts/database/migration_file.dart';
import '../../../contracts/database/schema_builder.dart';
import '../../../support/exceptions/database_exception.dart';
import '../database.dart';

class Migrator {
  final DatabaseManager manager;
  final List<MigrationFile> _migrations = [];
  SchemaBuilder get schemaBuilder => manager.schemaBuilder;

  Migrator(
    this.manager,
  );

  void registerAll(List<MigrationFile> migrations) {
    _migrations.addAll(migrations);
  }

  Future<void> upAll() async {
    await _ensureDatabaseExists();
    await _ensureMigrationTable();

    final ran = await _ranMigrations();
    Khadem.logger.warning('Running migrations...');
    for (final migration in _migrations) {
      if (ran.contains(migration.name)) {
        Khadem.logger.info('🔁 Skipped: ${migration.name} (already migrated)');
        continue;
      }

      Khadem.logger.info('⚙️ Running migration: ${migration.name}');
      await migration.up(manager.schemaBuilder);
      await _executeSchemaQueries();
      await _markAsRan(migration.name);
    }

    Khadem.logger.info('✅ All migrations executed successfully.');
  }

  Future<void> downAll() async {
    final ran = (await _ranMigrations()).reversed.toList();

    for (final migration in _migrations.reversed) {
      if (!ran.contains(migration.name)) continue;

      Khadem.logger.info('↩️ Reverting: ${migration.name}');
      await migration.down(manager.schemaBuilder);
      await _executeSchemaQueries();
      await _removeFromRan(migration.name);
    }
  }

  Future<void> reset() async {
    Khadem.logger.warning('⚠️ Resetting all migrations...');
    await downAll();
    await upAll();
  }

  Future<void> refresh() async {
    Khadem.logger.warning('🔁 Refreshing all migrations...');
    await downAll();
    await upAll();
  }

  Future<void> up(String name) async {
    final migration = _findMigration(name);
    await migration.up(manager.schemaBuilder);
    await _executeSchemaQueries();
    await _markAsRan(migration.name);
  }

  Future<void> down(String name) async {
    final migration = _findMigration(name);
    await migration.down(manager.schemaBuilder);
    await _executeSchemaQueries();
    await _removeFromRan(migration.name);
  }

  Future<void> status() async {
    final ran = await _ranMigrations();

    for (final migration in _migrations) {
      final status = ran.contains(migration.name) ? '✅ Ran' : '❌ Pending';
      Khadem.logger.info(' - ${migration.name}: $status');
    }
  }

  MigrationFile _findMigration(String name) {
    return _migrations.firstWhere(
      (m) => m.name == name,
      orElse: () => throw DatabaseException('Migration "$name" not found.'),
    );
  }

  Future<void> _ensureMigrationTable() async {
    schemaBuilder.createIfNotExists('migrations', (table) {
      table.id();
      table.string('name').unique();
      table.integer('batch').defaultVal(1);
      table.timestamp('migrated_at').nullable();
    });

    await _executeSchemaQueries();
  }

  Future<void> _markAsRan(String name) async {
    await manager.table('migrations').insert({
      'name': name,
      'batch': 1,
      'migrated_at': DateTime.now().toUtc(),
    });
  }

  Future<void> _removeFromRan(String name) async {
    await manager.table('migrations').where('name', '=', name).delete();
  }

  Future<List<String>> _ranMigrations() async {
    try {
      final results = await manager.table('migrations').select(['name']).get();
      return List<String>.from(results.map((row) => row['name']));
    } catch (e) {
      Khadem.logger.warning(
        '⚠️ Could not read migration status. Did you run "migrate"?',
      );
      return [];
    }
  }

  Future<void> _executeSchemaQueries() async {
    for (final sql in schemaBuilder.queries) {
      Khadem.logger.info('📥 Executing: $sql');
      await manager.connection().execute(sql);
    }
    schemaBuilder.queries.clear();
  }

  Future<void> _ensureDatabaseExists() async {
    final dbName = Khadem.config.get('database.database') as String;
    final dbConnection = manager.connection();

    try {
      await dbConnection.execute('USE $dbName');
    } catch (_) {
      Khadem.logger.warning('⚠️ Database "$dbName" does not exist.');

      // Check if stdin is available and in terminal mode
      if (stdin.hasTerminal) {
        try {
          // Temporarily restore terminal settings for user input
          final wasLineMode = stdin.lineMode;
          final wasEchoMode = stdin.echoMode;

          stdin.lineMode = true;
          stdin.echoMode = true;

          stdout.write('❓ Create it now? (y/n): ');
          final input = stdin.readLineSync();

          // Restore previous terminal settings
          try {
            stdin.lineMode = wasLineMode;
            stdin.echoMode = wasEchoMode;
          } catch (_) {
            // Ignore if we can't restore settings
          }

          if (input?.toLowerCase() == 'y') {
            await dbConnection
                .execute('CREATE DATABASE IF NOT EXISTS `$dbName`');
            Khadem.logger.info('✅ Database "$dbName" created.');
            await dbConnection.execute('USE $dbName');
            return;
          }
        } catch (e) {
          Khadem.logger.error('❌ Error reading user input: $e');
        }
      }

      // If we can't read input or user declined, auto-create the database
      Khadem.logger.info('🔧 Auto-creating database "$dbName"...');
      await dbConnection.execute('CREATE DATABASE IF NOT EXISTS `$dbName`');
      Khadem.logger.info('✅ Database "$dbName" created.');
      await dbConnection.execute('USE $dbName');
    }
  }
}

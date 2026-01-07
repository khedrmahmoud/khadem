import '../../../application/khadem.dart';
import '../../../contracts/database/migration_file.dart';
import '../../../contracts/database/schema_builder.dart';
import '../../../support/exceptions/database_exception.dart';
import '../database.dart';
import '../database_drivers/sqlite/sqlite_connection.dart';

class Migrator {
  final DatabaseManager manager;
  final List<MigrationFile> _migrations = [];
  late final SchemaBuilder _schemaBuilder;
  SchemaBuilder get schemaBuilder => _schemaBuilder;

  Migrator(
    this.manager,
  ) {
    _schemaBuilder = manager.schemaBuilder;
  }

  void registerAll(List<MigrationFile> migrations) {
    _migrations.addAll(migrations);
  }

  /// Run the pending migrations.
  Future<void> upAll({bool step = false}) async {
    await _ensureDatabaseExists();
    await _ensureMigrationTable();

    final ran = await _ranMigrations();
    final batch = await _getNextBatchNumber();

    Khadem.logger.info('🚀 Starting migration process (Batch $batch)...');

    int count = 0;
    for (final migration in _migrations) {
      if (ran.contains(migration.name)) {
        continue;
      }

      Khadem.logger.info('⚙️ Migrating: ${migration.name}');
      final startTime = DateTime.now();

      try {
        await migration.up(schemaBuilder);
        await _executeSchemaQueries();
        await _markAsRan(migration.name, batch);

        final duration = DateTime.now().difference(startTime).inMilliseconds;
        Khadem.logger.info('✅ Migrated:  ${migration.name} (${duration}ms)');
        count++;

        if (step) break;
      } catch (e) {
        Khadem.logger.error('❌ Migration failed: ${migration.name}');
        Khadem.logger.error(e.toString());
        rethrow;
      }
    }

    if (count == 0) {
      Khadem.logger.info('✨ Nothing to migrate.');
    } else {
      Khadem.logger.info('🎉 Successfully ran $count migrations.');
    }
  }

  /// Rollback the last migration operation.
  Future<void> rollback({int steps = 0}) async {
    final ran = await _getMigrationsToRollback(steps);

    if (ran.isEmpty) {
      Khadem.logger.info('✨ Nothing to rollback.');
      return;
    }

    Khadem.logger.info('Rolling back migrations...');

    for (final migrationRecord in ran) {
      final name = migrationRecord['name'] as String;
      final migration = _findMigration(name);

      Khadem.logger.info('⚙️ Rolling back: $name');
      final startTime = DateTime.now();

      try {
        await migration.down(schemaBuilder);
        await _executeSchemaQueries();
        await _removeFromRan(name);

        final duration = DateTime.now().difference(startTime).inMilliseconds;
        Khadem.logger.info('✅ Rolled back: $name (${duration}ms)');
      } catch (e) {
        Khadem.logger.error('❌ Rollback failed: $name');
        Khadem.logger.error(e.toString());
        rethrow;
      }
    }
  }

  /// Reset all migrations.
  Future<void> reset() async {
    Khadem.logger.warning('⚠️ Resetting all migrations...');
    final ran = await _ranMigrations();

    // Rollback in reverse order
    for (final name in ran.reversed) {
      final migration = _findMigration(name);
      Khadem.logger.info('⚙️ Rolling back: $name');
      await migration.down(schemaBuilder);
      await _executeSchemaQueries();
      await _removeFromRan(name);
    }

    Khadem.logger.info('✅ Database reset completed.');
  }

  /// Refresh the database (Reset + Up).
  Future<void> refresh() async {
    Khadem.logger.warning('🔁 Refreshing database...');
    await reset();
    await upAll();
    Khadem.logger.info('✅ Database refreshed.');
  }

  /// Drop all tables and re-run migrations.
  Future<void> fresh() async {
    Khadem.logger
        .warning('🧨 Dropping all tables and re-running migrations...');
    await _dropAllTables();
    await _ensureMigrationTable();
    await upAll();
    Khadem.logger.info('✅ Database fresh completed.');
  }

  Future<void> status() async {
    await _ensureDatabaseExists();
    await _ensureMigrationTable();

    final ran = await _getRanMigrationsWithDetails();
    final ranNames = ran.map((m) => m['name'] as String).toSet();

    Khadem.logger.info('\n📊 Migration Status:');
    Khadem.logger.info('--------------------------------------------------');
    Khadem.logger.info(
        '| Status   | Migration Name                           | Batch |',);
    Khadem.logger.info('--------------------------------------------------');

    for (final migration in _migrations) {
      final isRan = ranNames.contains(migration.name);
      final status = isRan ? '✅ Ran  ' : '❌ Pending';
      final batch = isRan
          ? ran
              .firstWhere((m) => m['name'] == migration.name)['batch']
              .toString()
          : '-';

      Khadem.logger.info(
          '| $status | ${migration.name.padRight(36)} | ${batch.padRight(5)} |',);
    }
    Khadem.logger.info('--------------------------------------------------\n');
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
      table.string('name');
      table.integer('batch');
      table.timestamp('migrated_at').nullable();
    });

    await _executeSchemaQueries();
  }

  Future<int> _getNextBatchNumber() async {
    final result = await manager.table('migrations').max('batch');
    return result + 1;
  }

  Future<void> _markAsRan(String name, int batch) async {
    await manager.table('migrations').insert({
      'name': name,
      'batch': batch,
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
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getRanMigrationsWithDetails() async {
    try {
      final results = await manager.table('migrations').orderBy('id').get();
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getMigrationsToRollback(int steps) async {
    final query = manager.table('migrations').orderBy('id', direction: 'DESC');

    if (steps > 0) {
      query.limit(steps);
    } else {
      final lastBatch = await manager.table('migrations').max('batch');
      query.where('batch', '=', lastBatch);
    }

    final results = await query.get();
    return results.cast<Map<String, dynamic>>();
  }

  Future<void> _dropAllTables() async {
    final dbConnection = manager.connection();

    if (dbConnection is SQLiteConnection) {
      await _dropAllTablesSQLite(dbConnection);
      return;
    }

    final response = await dbConnection.execute('SHOW TABLES');
    final tables = response.data;
    if (tables == null || tables.isEmpty) return;

    final dbName = Khadem.config.get('database.database') as String;
    final key = 'Tables_in_$dbName';

    await dbConnection.execute('SET FOREIGN_KEY_CHECKS = 0');
    for (final row in tables) {
      final tableName = row[key] ?? row.values.first;
      await dbConnection.execute('DROP TABLE IF EXISTS `$tableName`');
    }
    await dbConnection.execute('SET FOREIGN_KEY_CHECKS = 1');
  }

  Future<void> _dropAllTablesSQLite(SQLiteConnection connection) async {
    // Disable foreign keys to avoid constraint violations during drop
    await connection.unprepared('PRAGMA foreign_keys = OFF');

    try {
      final response = await connection.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      final tables = response.data;
      if (tables != null) {
        for (final row in tables) {
          final tableName = row['name'];
          await connection.execute('DROP TABLE IF EXISTS "$tableName"');
        }
      }
    } finally {
      await connection.unprepared('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _executeSchemaQueries() async {
    final queries = List<String>.from(schemaBuilder.queries);
    schemaBuilder.queries.clear();

    for (final sql in queries) {
      // Khadem.logger.info('📥 Executing: $sql');
      await manager.connection().execute(sql);
    }
  }

  Future<void> _ensureDatabaseExists() async {
    final dbConnection = manager.connection();

    // SQLite creates the database file automatically upon connection.
    if (dbConnection is SQLiteConnection) {
      return;
    }

    final dbName = Khadem.config.get('database.database') as String;

    try {
      await dbConnection.execute('USE $dbName');
    } catch (_) {
      Khadem.logger.info('🔧 Auto-creating database "$dbName"...');
      await dbConnection.execute('CREATE DATABASE IF NOT EXISTS `$dbName`');
      Khadem.logger.info('✅ Database "$dbName" created.');
      await dbConnection.execute('USE $dbName');
    }
  }
}

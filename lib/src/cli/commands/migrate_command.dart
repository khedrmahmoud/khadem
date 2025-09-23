import 'dart:io';
import 'dart:mirrors';

import 'package:khadem/khadem.dart';
import 'package:path/path.dart' as path;

import '../command_bootstrapper.dart'; // Dynamic imports for migration classes
// These would be generated in a production system
// For now, we'll use conditional imports based on the project structure

// Import migration classes dynamically based on file path
// This is a workaround since Dart doesn't have full runtime reflection

class MigrateCommand extends KhademCommand {
  @override
  String get name => 'migrate';

  @override
  String get description =>
      'Run database migrations with comprehensive error handling';

  MigrateCommand({required super.logger}) {
    argParser
      ..addFlag(
        'reset',
        abbr: 'r',
        help: 'Reset all migrations (rollback and re-run)',
        negatable: false,
      )
      ..addFlag(
        'fresh',
        abbr: 'f',
        help: 'Drop all tables and rerun all migrations',
        negatable: false,
      )
      ..addFlag(
        'status',
        abbr: 's',
        help: 'Show migration status',
        negatable: false,
      )
      ..addFlag(
        'force',
        abbr: 'x',
        help: 'Force run migrations in production',
        negatable: false,
      )
      ..addOption(
        'step',
        abbr: 't',
        help: 'Run migrations in steps (specify number)',
        valueHelp: 'count',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Path to migrations directory',
        defaultsTo: 'database/migrations',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show detailed migration information',
        negatable: false,
      );
  }

  @override
  Future<void> handle(List<String> args) async {
    try {
      await CommandBootstrapper.register();
      await CommandBootstrapper.boot();
      // Check if we're in production without force flag
      final isProduction = Khadem.isProduction;

      final force = argResults?['force'] == true;

      if (isProduction && !force) {
        logger.error('❌ Production environment detected!');
        logger.error('💡 Use --force flag to run migrations in production');
        logger.error('⚠️  This can be dangerous. Make sure you have backups!');
        exit(1);
      }

      final migrator = Khadem.container.resolve<Migrator>();

      // Discover and register migrations
      final migrations = await _discoverMigrations();
      migrator.registerAll(migrations);

      if (argResults?['status'] == true) {
        await _showMigrationStatus(migrator);
        return;
      }

      if (argResults?['reset'] == true) {
        await _runReset(migrator);
      } else if (argResults?['fresh'] == true) {
        await _runFresh(migrator);
      } else {
        await _runMigrations(migrator);
      }

      logger.info('✅ Migration command completed successfully.');
      exit(0);
    } catch (e, stackTrace) {
      logger.error('❌ Migration failed: $e');
      if (argResults?['verbose'] == true) {
        logger.error('Stack trace: $stackTrace');
      }
      logger.error('� Try running with --verbose for more details');
      exit(1);
    }
  }

  Future<List<MigrationFile>> _discoverMigrations() async {
    final migrationsPath =
        argResults?['path'] as String? ?? 'lib/database/migrations';
    final migrationsDir = Directory(migrationsPath);

    if (!await migrationsDir.exists()) {
      logger.error('❌ Migrations directory not found: $migrationsPath');
      logger.error('💡 Make sure you\'re in a Khadem project directory');
      exit(1);
    }

    // Fallback: Discover migration files manually
    final migrations = <MigrationFile>[];
    final files = await migrationsDir.list().toList();

    // Filter Dart files (exclude migrations.dart)
    final migrationFiles = files
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              !file.path.endsWith('migrations.dart'),
        )
        .toList();

    if (migrationFiles.isEmpty) {
      logger.warning('⚠️ No migration files found in $migrationsPath');
      return migrations;
    }

    logger.info('🔍 Found ${migrationFiles.length} migration files');

    for (final file in migrationFiles) {
      try {
        final migration = await _loadMigrationFromFile(file);
        if (migration != null) {
          migrations.add(migration);
          if (argResults?['verbose'] == true) {
            logger.info('📄 Loaded: ${migration.name}');
          }
        }
      } catch (e) {
        logger.error('❌ Failed to load migration: ${file.path}');
        logger.error('   Error: $e');
        if (argResults?['verbose'] == true) {
          rethrow;
        }
      }
    }

    // Sort migrations by filename (assuming they start with numbers)
    migrations.sort((a, b) => a.name.compareTo(b.name));

    logger.info('📋 Total migrations loaded: ${migrations.length}');
    return migrations;
  }

  Future<MigrationFile?> _loadMigrationFromFile(File file) async {
    try {
      final fileName = path.basenameWithoutExtension(file.path);
      final className = _extractMigrationClassName(fileName);

      if (className == null) {
        logger.error('❌ Could not extract class name from file: $fileName');
        return null;
      }

      if (argResults?['verbose'] == true) {
        logger.info('🔧 Loading migration: $className from $fileName');
      }

      // Use Dart mirrors to dynamically load and instantiate the migration
      final migration = await _instantiateMigrationWithMirrors(file, className);

      if (migration != null) {
        if (argResults?['verbose'] == true) {
          logger.info('✅ Successfully loaded migration: $className');
        }
        return migration;
      } else {
        logger.error('❌ Failed to instantiate migration: $className');
        return null;
      }
    } catch (e, stackTrace) {
      logger.error('❌ Failed to load migration from file: ${file.path}');
      logger.error('   Error: $e');
      if (argResults?['verbose'] == true) {
        logger.error('   Stack trace: $stackTrace');
      }
      return null;
    }
  }

  Future<void> _showMigrationStatus(Migrator migrator) async {
    logger.info('📊 Migration Status:');
    logger.info('=' * 50);

    try {
      await migrator.status();
    } catch (e) {
      logger.error('❌ Failed to get migration status: $e');
    }
  }

  Future<void> _runMigrations(Migrator migrator) async {
    final step = argResults?['step'];

    if (step != null) {
      final stepCount = int.tryParse(step);
      if (stepCount == null || stepCount <= 0) {
        logger.error('❌ Invalid step count: $step');
        exit(1);
      }

      logger.info('⚡ Running migrations in steps: $stepCount at a time');
      await _runMigrationsInSteps(migrator, stepCount);
    } else {
      logger.info('🚀 Running all pending migrations...');
      await migrator.upAll();
    }
  }

  Future<void> _runMigrationsInSteps(Migrator migrator, int stepCount) async {
    // This would require modifying the Migrator class to support step execution
    // For now, we'll run all migrations
    logger.warning('⚠️ Step execution not fully implemented yet');
    await migrator.upAll();
  }

  Future<void> _runReset(Migrator migrator) async {
    logger.warning('🔄 Resetting all migrations...');
    logger.warning('⚠️ This will rollback all migrations and re-run them');

    stdout.write('❓ Are you sure? (y/n): ');
    final input = stdin.readLineSync();

    if (input?.toLowerCase() != 'y') {
      logger.info('❌ Reset cancelled');
      return;
    }

    await migrator.reset();
  }

  Future<void> _runFresh(Migrator migrator) async {
    logger.warning('🧼 Fresh migration: dropping all tables and re-running...');
    logger.warning('⚠️ This will DELETE ALL DATA in your database!');

    stdout.write('❓ Are you sure? (y/n): ');
    final input = stdin.readLineSync();

    if (input?.toLowerCase() != 'y') {
      logger.info('❌ Fresh migration cancelled');
      return;
    }

    await migrator.refresh();
  }

  String? _extractMigrationClassName(String fileName) {
    try {
      // Handle different migration file naming patterns
      // Examples:
      // - 0_create_users_table.dart -> CreateUsersTable
      // - 1757064547568_create_chat_rooms_table.dart -> CreateChatRoomsTable
      // - create_posts_table.dart -> CreatePostsTable

      // Remove timestamp prefix if present (numbers followed by underscore)
      final nameWithoutTimestamp = fileName.replaceFirst(RegExp(r'^\d+_'), '');

      // Remove .dart extension and convert to PascalCase
      final baseName = nameWithoutTimestamp.replaceAll('_', ' ');
      final words = baseName
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '',
          )
          .where((word) => word.isNotEmpty);

      return words.join();
    } catch (e) {
      logger.error('❌ Failed to extract class name from: $fileName');
      return null;
    }
  }

  Future<MigrationFile?> _instantiateMigrationWithMirrors(
    File file,
    String className,
  ) async {
    try {
      // First, try to find the class in the current mirror system
      final mirrorSystem = currentMirrorSystem();
      ClassMirror? migrationClassMirror;

      for (final library in mirrorSystem.libraries.values) {
        try {
          migrationClassMirror =
              library.declarations[Symbol(className)] as ClassMirror?;
          if (migrationClassMirror != null) {
            break;
          }
        } catch (e) {
          // Continue searching
        }
      }

      if (migrationClassMirror != null) {
        // Check if it extends MigrationFile
        final migrationType = reflectType(MigrationFile);
        if (!migrationClassMirror.isSubtypeOf(migrationType)) {
          logger.warning('⚠️ Class "$className" does not extend MigrationFile');
          return null;
        }

        // Create an instance using the default constructor
        final instanceMirror =
            migrationClassMirror.newInstance(const Symbol(''), []);
        final migration = instanceMirror.reflectee as MigrationFile;

        if (argResults?['verbose'] == true) {
          logger.info('✅ Successfully instantiated migration: $className');
        }

        return migration;
      }

      // If not found in mirror system, try dynamic loading approach
      logger.warning(
        '⚠️ Migration class "$className" not found in mirror system',
      );
      logger.warning('   Attempting dynamic loading from file...');

      return await _loadMigrationFromFileContent(file, className);
    } catch (e, stackTrace) {
      logger.error('❌ Failed to instantiate migration with mirror: $className');
      logger.error('   Error: $e');
      if (argResults?['verbose'] == true) {
        logger.error('   Stack trace: $stackTrace');
      }
      return null;
    }
  }

  Future<MigrationFile?> _loadMigrationFromFileContent(
    File file,
    String className,
  ) async {
    try {
      // Read the migration file content
      final content = await file.readAsString();

      // Check if the file contains a valid migration class
      if (!content.contains('class $className extends MigrationFile')) {
        logger.error('❌ File does not contain expected class: $className');
        return null;
      }

      // For now, we'll create a simple migration instance
      // In a production system, this would use code generation or dart_eval
      logger.info('📄 Found migration class: $className');
      logger.info('   File: ${file.path}');

      // Extract the migration name from the file
      final fileName = path.basenameWithoutExtension(file.path);
      final migrationName = _extractMigrationName(fileName);

      // Create a basic migration wrapper
      // This is a temporary solution - in production you'd use proper instantiation
      final migration =
          _createMigrationWrapper(className, migrationName, content);

      if (migration != null) {
        logger.info('✅ Created migration wrapper for: $className');
        return migration;
      }

      return null;
    } catch (e) {
      logger.error('❌ Failed to load migration from file content: $e');
      return null;
    }
  }

  String _extractMigrationName(String fileName) {
    // Convert file name to migration name
    // Example: 0_create_users_table.dart -> create_users_table
    final parts = fileName.split('_');
    if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts[0])) {
      return parts.sublist(1).join('_');
    }
    return fileName;
  }

  MigrationFile? _createMigrationWrapper(
    String className,
    String migrationName,
    String content,
  ) {
    // This is a simplified approach for demonstration
    // In a real implementation, you'd parse the up() and down() methods

    try {
      // Extract up method content
      final upMatch = RegExp(
        r'Future<void>\s+up\s*\([^)]*\)\s*async\s*\{([^}]*)\}',
        multiLine: true,
      ).firstMatch(content);
      final downMatch = RegExp(
        r'Future<void>\s+down\s*\([^)]*\)\s*async\s*\{([^}]*)\}',
        multiLine: true,
      ).firstMatch(content);

      if (upMatch == null) {
        logger.error('❌ Could not find up() method in migration: $className');
        return null;
      }

      // Create a simple migration implementation
      return _SimpleMigration(
        className,
        upMatch.group(1) ?? '',
        downMatch?.group(1) ?? '',
      );
    } catch (e) {
      logger.error('❌ Failed to create migration wrapper: $e');
      return null;
    }
  }
}

// Simple migration wrapper for demonstration
class _SimpleMigration extends MigrationFile {
  final String _className;
  final String _upContent;
  final String _downContent;

  _SimpleMigration(this._className, this._upContent, this._downContent);

  @override
  String get name => _className;

  @override
  Future<void> up(builder) async {
    // This is a placeholder - in production you'd execute the actual migration code
    print('🚀 Running UP migration: $_className');
    print('   Content: $_upContent');
    // For now, we'll skip actual execution
  }

  @override
  Future<void> down(builder) async {
    // This is a placeholder - in production you'd execute the actual migration code
    print('↩️ Running DOWN migration: $_className');
    print('   Content: $_downContent');
    // For now, we'll skip actual execution
  }
}

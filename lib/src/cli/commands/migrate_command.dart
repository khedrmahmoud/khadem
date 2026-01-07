import 'dart:io';
import 'package:khadem/khadem.dart';

import '../bus/command.dart';

class MigrateCommand extends KhademCommand {
  @override
  bool get requiresKernelBootstrap => true;

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
      // Check if we're in production without force flag
      final isProduction = Khadem.isProduction;

      final force = argResults?['force'] == true;

      if (isProduction && !force) {
        logger.error('❌ Production environment detected!');
        logger.error('💡 Use --force flag to run migrations in production');
        logger.error('⚠️  This can be dangerous. Make sure you have backups!');
        exitCode = 1;
        return;
      }

      final migrator = Khadem.container.resolve<Migrator>();

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
      exitCode = 0;
      return;
    } catch (e, stackTrace) {
      logger.error('❌ Migration failed: $e');
      if (argResults?['verbose'] == true) {
        logger.error('Stack trace: $stackTrace');
      }
      logger.error('💡 Try running with --verbose for more details');
      exitCode = 1;
      return;
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
        exitCode = 1;
        return;
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
}

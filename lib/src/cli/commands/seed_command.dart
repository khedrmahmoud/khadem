import 'dart:io';

import '../../application/khadem.dart';
import '../../core/database/migration/seeder.dart';
import '../../support/exceptions/database_exception.dart';
import '../bus/command.dart';

class DbSeedCommand extends KhademCommand {
  @override
  bool get requiresKernelBootstrap => true;

  @override
  String get name => 'db:seed';

  @override
  String get description => 'Run database seeders';

  DbSeedCommand({required super.logger}) {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force run seeders in production',
        negatable: false,
      )
      ..addOption(
        'class',
        abbr: 'c',
        help: 'Run a specific seeder class',
        valueHelp: 'className',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show detailed seeder information',
        negatable: false,
      );
  }

  @override
  Future<void> handle(List<String> args) async {
    try {
      final databaseReady = _isDatabaseConfigured();
      if (!databaseReady) {
        exitCode = 1;
        return;
      }

      try {
        await Khadem.db.init();
      } on SocketException catch (e) {
        logger.error('❌ Database connection failed: $e');
        logger.error('');
        logger.error('To fix:');
        logger.error('- Ensure your database server is running');
        logger.error('- Verify `.env` DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD');
        logger.error(
          '- Or switch to sqlite by setting DB_CONNECTION=sqlite and DB_DATABASE=storage/database.sqlite',
        );
        exitCode = 1;
        return;
      }
      // Check if we're in production without force flag
      final isProduction = Khadem.isProduction;
      final force = argResults?['force'] == true;

      if (isProduction && !force) {
        logger.error('❌ Production environment detected!');
        logger.error('💡 Use --force flag to run seeders in production');
        logger.error('⚠️  This can be dangerous. Make sure you have backups!');
        exitCode = 1;
        return;
      }

      final seederManager = Khadem.container.resolve<SeederManager>();

      final specificClass = argResults?['class'] as String?;

      if (specificClass != null) {
        await _runSpecificSeeder(seederManager, specificClass);
      } else {
        await _runAllSeeders(seederManager);
      }

      logger.info('✅ Database seeding completed successfully.');
      exitCode = 0;
      return;
    } on DatabaseException catch (e, stackTrace) {
      logger.error('❌ Seeding failed: ${e.message}');
      if (argResults?['verbose'] == true) {
        logger.error('Stack trace: $stackTrace');
      }
      exitCode = 1;
      return;
    } catch (e, stackTrace) {
      logger.error('❌ Seeding failed: $e');
      if (argResults?['verbose'] == true) {
        logger.error('Stack trace: $stackTrace');
      }
      logger.error('💡 Try running with --verbose for more details');
      exitCode = 1;
      return;
    }
  }

  bool _isDatabaseConfigured() {
    final config = Khadem.config;
    final defaultName = config.get<String>('database.default', 'mysql')!;

    final conn =
        config.get<Map<String, dynamic>>('database.connections.$defaultName');
    if (conn != null) {
      return true;
    }

    final legacy = config.section('database');
    if (legacy == null) {
      return false;
    }

    // Legacy single-connection config is allowed when it does NOT contain
    // a `connections` map.
    if (legacy.containsKey('connections')) {
      return false;
    }

    return true;
  }

  Future<void> _runAllSeeders(SeederManager seederManager) async {
    logger.info('🚀 Running all seeders...');
    await seederManager.runAll();
  }

  Future<void> _runSpecificSeeder(
    SeederManager seederManager,
    String className,
  ) async {
    logger.info('🎯 Running specific seeder: $className');
    await seederManager.run(className);
  }
}

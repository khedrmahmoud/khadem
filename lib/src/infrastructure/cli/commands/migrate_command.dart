import 'dart:io';

import '../../../core/database/migration/migrator.dart';
import '../../../application/khadem.dart';
import '../bus/command.dart';

class MigrateCommand extends KhademCommand {
  @override
  String get name => 'migrate';
  @override
  String get description => 'Run all pending migrations';

  MigrateCommand({required super.logger}) {
    argParser
      ..addFlag('reset', abbr: 'r', help: 'Reset migrations')
      ..addFlag('fresh',
          abbr: 'f', help: 'Drop all tables and rerun all migrations');
  }

  @override
  Future<void> handle(List<String> args) async {
    final migrator = Khadem.container.resolve<Migrator>();

    if (argResults?['reset'] == true) {
      logger.warning('🔄 Resetting all migrations...');
      await migrator.reset();
    } else if (argResults?['fresh'] == true) {
      logger.warning('🧼 Fresh migration: dropping all and migrating again...');
      await migrator.refresh();
    } else {
      await migrator.upAll();
    }

    logger.info('✅ Migration command complete.');
    exit(0);
  }
}

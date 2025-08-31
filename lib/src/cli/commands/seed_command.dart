import 'dart:io';

import '../../application/khadem.dart';
import '../../core/database/migration/seeder.dart';
import '../bus/command.dart';

class DbSeedCommand extends KhademCommand {
  DbSeedCommand({required super.logger});

  @override
  String get name => 'db:seed';
  @override
  String get description => 'Run all seeders';

  @override
  Future<void> handle(List<String> args) async {
    final seeder = Khadem.container.resolve<SeederManager>();
    await seeder.runAll();
    logger.info('✅ Database seeded successfully.');
    exit(0);
  }
}

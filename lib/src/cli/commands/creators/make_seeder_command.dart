import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeSeederCommand extends KhademCommand {
  MakeSeederCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Seeder name (e.g. UserSeeder or auth/UserSeeder)',
    );
  }

  @override
  String get name => 'make:seeder';

  @override
  String get description => 'Create a new database seeder and update registry.';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:seeder --name=UserSeeder');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final raw = parts.name;

    final classBase =
        CliNaming.ensureSuffix(CliNaming.toPascalCase(raw), 'Seeder');
    final fileBaseRaw = CliNaming.toSnakeCase(raw);
    final fileBase = fileBaseRaw.endsWith('_seeder')
        ? fileBaseRaw
        : CliNaming.ensureSuffix(fileBaseRaw, '_seeder');

    final seederDir = folder.isEmpty
        ? 'lib/database/seeders'
        : 'lib/database/seeders/$folder';

    final filePath = '$seederDir/$fileBase.dart';
    final file = File(filePath);

    if (await file.exists()) {
      logger.error('❌ Seeder file already exists at $filePath');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);

    await file.writeAsString(
      '''
import 'package:khadem/contracts.dart' show Seeder;

class $classBase extends Seeder {
  @override
  Future<void> run() async {
    // TODO: implement seeding logic
    Log.info('🌱 Running $classBase...');

  }
}
'''
          .trim(),
    );

    logger.info('✅ Seeder "$classBase" created successfully at $filePath');

    await _updateSeedersRegistry();
    logger.info('🔄 seeders.dart updated successfully.');

    exitCode = 0;
  }

  Future<void> _updateSeedersRegistry() async {
    final dir = Directory('lib/database/seeders');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.dart') && !f.path.endsWith('seeders.dart'),
        )
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final buffer = StringBuffer();
    buffer.writeln("import 'package:khadem/contracts.dart' show Seeder;\n");

    final classNames = <String>[];

    for (final file in files) {
      final fileName = file.uri.pathSegments.last;
      final relative = file.path.replaceAll('\\', '/');
      final importPath = relative.split('lib/database/seeders/').last;

      // Example: user_seeder.dart => UserSeeder
      final className = CliNaming.ensureSuffix(
        CliNaming.toPascalCase(fileName.replaceAll('.dart', '')),
        'Seeder',
      );

      classNames.add(className);
      buffer.writeln("import '$importPath';");
    }

    buffer.writeln(
      '\n// Seeder registry - automatically maintained by the seeder generator',
    );
    buffer.writeln(
      "// This file is used by the 'khadem db:seed' command to discover and run seeders",
    );
    buffer.writeln('List<Seeder> seedersList = <Seeder>[');
    for (final className in classNames) {
      buffer.writeln('  $className(),');
    }
    buffer.writeln('];');

    final output = File('lib/database/seeders/seeders.dart');
    await output.writeAsString(buffer.toString());
  }
}

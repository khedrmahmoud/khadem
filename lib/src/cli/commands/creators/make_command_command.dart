import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeCommandCommand extends KhademCommand {
  MakeCommandCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Command name (e.g. report:daily or tools/CleanCache)',
    );
  }

  @override
  String get name => 'make:command';

  @override
  String get description => 'Create a new custom CLI command in app/commands.';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:command --name=tools/CleanCache');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final raw = parts.name;

    // Accept either a CLI name (report:daily) or a class-ish name (CleanCache).
    final commandName = raw.contains(':')
        ? raw
        : CliNaming.toSnakeCase(raw).replaceAll('_', ':');

    final classBase = raw.contains(':')
        ? raw
              .split(':')
              .where((p) => p.isNotEmpty)
              .map(CliNaming.toPascalCase)
              .join()
        : CliNaming.toPascalCase(raw);

    final className = CliNaming.ensureSuffix(classBase, 'Command');

    final fileBase = CliNaming.toSnakeCase(classBase);
    final filePath = folder.isEmpty
        ? 'app/commands/${fileBase}_command.dart'
        : 'app/commands/$folder/${fileBase}_command.dart';

    final file = File(filePath);
    if (await file.exists()) {
      logger.error('❌ Command file already exists at $filePath');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);

    await file.writeAsString('''
import 'package:khadem/contracts.dart' show KhademCommand, LoggerContract;

class $className extends KhademCommand {
  @override
  String get name => '$commandName';

  @override
  String get description => 'Describe what this command does.';

  $className({required LoggerContract logger}) : super(logger: logger);

  @override
  Future<void> handle(List<String> args) async {
    // TODO: implement
    logger.info('✅ $commandName executed');
    exitCode = 0;
  }
}
''');

    logger.info('✅ Command "$commandName" created at $filePath');
    logger.info('💡 Tip: ensure it ends with _command.dart for auto-discovery');
    exitCode = 0;
  }
}

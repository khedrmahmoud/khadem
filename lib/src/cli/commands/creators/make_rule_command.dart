import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeRuleCommand extends KhademCommand {
  MakeRuleCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Rule name (e.g. UppercaseRule)',
    );
  }

  @override
  String get name => 'make:rule';

  @override
  String get description => 'Create a new validation rule';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:rule --name=UppercaseRule');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final rawName = parts.name;
    final className = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawName),
      'Rule',
    );
    final fileName =
        '${CliNaming.toSnakeCase(className.replaceAll('Rule', ''))}_rule.dart';

    final relativePath = folder.isEmpty
        ? 'lib/app/rules/$fileName'
        : 'lib/app/rules/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Rule "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(_stub(className));

    logger.info('✅ Rule "$className" created at "$relativePath"');
    exitCode = 0;
  }

  String _stub(String className) {
    return '''
import 'package:khadem/contracts.dart';

class $className extends Rule {
  @override
  String get signature => '${CliNaming.toSnakeCase(className)}';

  @override
  bool passes(ValidationContext context) {
    // TODO: Implement validation logic
    return true;
  }

  @override
  String message(ValidationContext context) =>
      '${CliNaming.toSnakeCase(className)}_validation';
}
''';
  }
}

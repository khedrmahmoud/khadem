import 'dart:io';

import '../../bus/command.dart';
import '../../utils/cli_naming.dart';

class MakePolicyCommand extends KhademCommand {
  MakePolicyCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Policy name (e.g. UserPolicy)',
    );
    argParser.addOption(
      'model',
      abbr: 'm',
      help: 'Model name to bind to (e.g. User)',
    );
  }

  @override
  String get name => 'make:policy';

  @override
  String get description => 'Create a new policy class';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:policy --name=UserPolicy');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final rawName = parts.name;
    final className = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawName),
      'Policy',
    );
    final fileName =
        '${CliNaming.toSnakeCase(className.replaceAll('Policy', ''))}_policy.dart';

    final relativePath = folder.isEmpty
        ? 'lib/app/policies/$fileName'
        : 'lib/app/policies/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Policy "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    final modelInput = argResults?['model'] as String?;
    final modelClass =
        modelInput != null ? CliNaming.toPascalCase(modelInput) : null;

    await file.create(recursive: true);
    await file.writeAsString(_stub(className, modelClass));

    logger.info('✅ Policy "$className" created at "$relativePath"');
    exitCode = 0;
  }

  String _stub(String className, String? modelClass) {
    final methods = modelClass != null
        ? '''
  bool view(Authenticatable user, dynamic model) {
    return true;
  }

  bool create(Authenticatable user) {
    return true;
  }

  bool update(Authenticatable user, dynamic model) {
    return true;
  }

  bool delete(Authenticatable user, dynamic model) {
    return true;
  }
'''
        : '''
  bool view(Authenticatable user) {
    return true;
  }
''';

    return '''
import 'package:khadem/khadem.dart' show Authenticatable;

class $className {
$methods
}
''';
  }
}

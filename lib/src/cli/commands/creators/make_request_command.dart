import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeRequestCommand extends KhademCommand {
  MakeRequestCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Request name (e.g. LoginRequest)',
    );
  }

  @override
  String get name => 'make:request';

  @override
  String get description => 'Create a new form request class';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:request --name=LoginRequest');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final rawName = parts.name;
    final className = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawName),
      'Request',
    );
    final fileName =
        '${CliNaming.toSnakeCase(className.replaceAll('Request', ''))}_request.dart';

    final relativePath = folder.isEmpty
        ? 'lib/app/http/requests/$fileName'
        : 'lib/app/http/requests/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Request "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(_stub(className));

    logger.info('✅ Request "$className" created at "$relativePath"');
    exitCode = 0;
  }

  String _stub(String className) {
    return '''
import 'package:khadem/http.dart';

class $className extends FormRequest {
  @override
  bool authorize(Request request) => true;

  @override
  Map<String, dynamic> rules() {
    return {
      // 'field_name': ['required', 'email'],
    };
  }

  @override
  Future<void> prepareForValidation(Request request) async {
    // TODO: Prepare data before validation
    // e.g., trim strings, convert types, etc.
    // request.merge({'field_name': request.input('field_name')?.trim()});
  }
}
''';
  }
}

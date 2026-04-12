import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeExceptionCommand extends KhademCommand {
  MakeExceptionCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Exception name (e.g. InvalidOrderException)',
    );
  }

  @override
  String get name => 'make:exception';

  @override
  String get description => 'Create a new custom exception class';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error(
        '❌ Usage: khadem make:exception --name=InvalidOrderException',
      );
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final rawName = parts.name;
    final className = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawName),
      'Exception',
    );
    final fileName =
        '${CliNaming.toSnakeCase(className.replaceAll('Exception', ''))}_exception.dart';

    final relativePath = folder.isEmpty
        ? 'lib/app/exceptions/$fileName'
        : 'lib/app/exceptions/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Exception "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(_stub(className));

    logger.info('✅ Exception "$className" created at "$relativePath"');
    exitCode = 0;
  }

  String _stub(String className) {
    return '''
import 'package:khadem/contracts.dart' show AppException;


class $className extends AppException {
  $className([
    String message = 'Error occurred',
    int statusCode = 500,
  ]) : super(
          message,
          statusCode: statusCode,
          title: '$className',
        );
}
''';
  }
}

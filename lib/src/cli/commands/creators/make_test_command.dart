import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeTestCommand extends KhademCommand {
  MakeTestCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Test name (e.g. UserTest)');
    argParser.addFlag('unit', abbr: 'u', help: 'Create a unit test');
  }

  @override
  String get name => 'make:test';

  @override
  String get description => 'Create a new test file';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:test --name=UserTest');
      exitCode = 1;
      return;
    }

    final isUnit = argResults?['unit'] as bool? ?? false;
    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final rawName = parts.name;
    final className = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawName),
      'Test',
    );
    final fileName =
        '${CliNaming.toSnakeCase(className.replaceAll('Test', ''))}_test.dart';

    final baseFolder = isUnit ? 'test/unit' : 'test/feature';
    final relativePath = folder.isEmpty
        ? '$baseFolder/$fileName'
        : '$baseFolder/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Test "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(_stub(className));

    logger.info('✅ Test "$className" created at "$relativePath"');
    exitCode = 0;
  }

  String _stub(String className) {
    return '''
import 'package:test/test.dart';
import 'package:khadem/khadem.dart';

void main() {
  group('$className', () {
    test('example test', () {
      expect(true, isTrue);
    });
  });
}
''';
  }
}

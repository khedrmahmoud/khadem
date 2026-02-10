import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeEventCommand extends KhademCommand {
  MakeEventCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Event name with optional path (e.g. User/Registered)',
    );
  }

  @override
  String get name => 'make:event';

  @override
  String get description => 'Create a new application event class';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:event --name=User/Registered');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;

    final rawEventName = parts.name;
    final eventClassName = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawEventName),
      'Event',
    );

    final eventBase = eventClassName.replaceAll('Event', '');
    final fileName = '${CliNaming.toSnakeCase(eventBase)}_event.dart';

    final relativePath = folder.isEmpty
        ? 'lib/app/events/$fileName'
        : 'lib/app/events/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Event "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(_stub(eventClassName));

    logger.info('✅ Event "$eventClassName" created at "$relativePath"');
    exitCode = 0;
  }

  String _stub(String className) {
    return '''
import 'package:khadem/contracts.dart' show Event;

class $className extends Event {
  final Map<String, dynamic> data;

  $className(this.data);
}
''';
  }
}

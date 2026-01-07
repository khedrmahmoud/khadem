import 'dart:io';

import '../../bus/command.dart';
import '../../utils/cli_naming.dart';

class MakeResourceCommand extends KhademCommand {
  MakeResourceCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Resource name (e.g. UserResource)',
    );
  }

  @override
  String get name => 'make:resource';

  @override
  String get description => 'Create a new API resource class';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:resource --name=UserResource');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final rawName = parts.name;
    final className = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawName),
      'Resource',
    );
    final fileName =
        '${CliNaming.toSnakeCase(className.replaceAll('Resource', ''))}_resource.dart';

    final relativePath = folder.isEmpty
        ? 'lib/app/http/resources/$fileName'
        : 'lib/app/http/resources/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Resource "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(_stub(className));

    logger.info('✅ Resource "$className" created at "$relativePath"');
    exitCode = 0;
  }

  String _stub(String className) {
    return '''
import 'package:khadem/khadem.dart';

class $className {
  final dynamic resource;

  $className(this.resource);

  Map<String, dynamic> toMap() {
    if (resource is Map<String, dynamic>) {
      return Map<String, dynamic>.from(resource as Map);
    }
    if (resource is KhademModel) {
      return (resource as KhademModel).toJson();
    }
    return {'data': resource};
  }
}
''';
  }
}

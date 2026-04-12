import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeControllerCommand extends KhademCommand {
  MakeControllerCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Controller name (e.g., PostsController or auth/AuthController)',
    );
  }

  @override
  String get name => 'make:controller';
  @override
  String get description =>
      'Create a new controller class with optional folder structure';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      logger.error(
        'Usage: khadem make:controller --name=ControllerName or --name=folder/ControllerName',
      );
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(name);
    final folder = parts.folder;
    final rawControllerName = parts.name;
    final controllerName = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawControllerName),
      'Controller',
    );

    final fileName = CliNaming.toSnakeCase(
      controllerName.replaceAll('Controller', ''),
    );
    final relativePath = folder.isEmpty
        ? 'lib/app/http/controllers/${fileName}_controller.dart'
        : 'lib/app/http/controllers/$folder/${fileName}_controller.dart';

    final file = File(relativePath);
    await file.create(recursive: true);

    await file.writeAsString(_controllerStub(controllerName, fileName, folder));
    logger.info('✅ Controller "$controllerName" created at "$relativePath".');
    exitCode = 0;
    return;
  }

  String _controllerStub(String className, String fileName, String folder) {
    final namespace = folder.isEmpty ? '' : '$folder/';
    return '''
import 'package:khadem/http.dart' show Request, Response;

class $className {
  Future index(Request req, Response res) async {
    res.sendJson({'message': '${namespace}$fileName index'});
  }

  Future show(Request req, Response res) async {
    final id = req.param('id');
    res.sendJson({'message': '${namespace}$fileName show \$id'});
  }

  Future create(Request req, Response res) async {
    res.sendJson({'message': '${namespace}$fileName created'});
  }

  Future update(Request req, Response res) async {
   final id = req.param('id');
    res.sendJson({'message': '${namespace}$fileName updated \$id'});
  }

  Future delete(Request req, Response res) async {
   final id = req.param('id');
    res.sendJson({'message': '${namespace}$fileName deleted \$id'});
  }
}
''';
  }
}

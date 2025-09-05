import 'dart:io';

import '../../bus/command.dart';

class MakeControllerCommand extends KhademCommand {
  MakeControllerCommand({required super.logger}) {
    argParser.addOption('name',
        abbr: 'n',
        help: 'Controller name (e.g., PostsController or auth/AuthController)',);
  }

  @override
  String get name => 'make:controller';
  @override
  String get description =>
      'Create a new controller class with optional folder structure';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null) {
      logger.error(
          'Usage: khadem make:controller --name=ControllerName or --name=folder/ControllerName',);
      exit(1);
    }

    // Parse folder and controller name
    final parts = name.split('/');
    String folder = '';
    final rawControllerName = parts.last;

    if (parts.length > 1) {
      folder = parts.sublist(0, parts.length - 1).join('/');
    }

    // Clean and format controller name
    String controllerName = _formatControllerName(rawControllerName);

    final fileName = _toSnakeCase(controllerName.replaceAll('Controller', ''));
    final relativePath = folder.isEmpty
        ? 'app/http/controllers/${fileName}_controller.dart'
        : 'app/http/controllers/$folder/${fileName}_controller.dart';

    final file = File(relativePath);
    await file.create(recursive: true);

    await file.writeAsString(_controllerStub(controllerName, fileName, folder));
    logger.info('✅ Controller "$controllerName" created at "$relativePath".');
    exit(0);
  }

  String _formatControllerName(String name) {
    // Remove 'Controller' suffix if present
    String baseName = name.replaceAll(RegExp(r'Controller$'), '');

    // Capitalize first letter and add 'Controller' suffix
    String capitalized = baseName.isNotEmpty
        ? '${baseName[0].toUpperCase()}${baseName.substring(1)}'
        : '';

    return '${capitalized}Controller';
  }

  String _toSnakeCase(String input) {
    if (input.isEmpty) return 'controller';

    return input.replaceAllMapped(
        RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}'
    ).replaceFirst(RegExp(r'^_'), '');
  }

  String _controllerStub(String className, String fileName, String folder) {
    final namespace = folder.isEmpty ? '' : '$folder/';
    return '''
import 'package:khadem/khadem_dart.dart' show Request, Response;

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

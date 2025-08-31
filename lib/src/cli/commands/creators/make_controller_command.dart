import 'dart:io';

import '../../bus/command.dart';

class MakeControllerCommand extends KhademCommand {
  MakeControllerCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Controller name');
  }

  @override
  String get name => 'make:controller';
  @override
  String get description => 'Create a new controller class';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null) {
      logger.error('Usage: khadem make:controller --name=PostsController');
      exit(1);
    }

    final fileName = _toSnakeCase(name.replaceAll('Controller', ''));
    final path = 'app/http/controllers/$fileName.dart';

    final file = File(path);
    await file.create(recursive: true);

    await file.writeAsString(_controllerStub(name, fileName));
    logger.info('✅ Controller "$name" created at "$path".');
    exit(0);
  }

  String _toSnakeCase(String input) {
    return '${input.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}').replaceFirst('_', '')}_controller';
  }

  String _controllerStub(String className, String fileName) {
    return '''
import 'package:khadem/khadem_dart.dart' show Request, Response;

class $className {
  Future index(Request req, Response res) async {
    res.sendJson({'message': '$fileName index'});
  }

  Future show(Request req, Response res) async {
    final id = req.params['id'];
    res.sendJson({'message': '$fileName show \$id'});
  }

  Future create(Request req, Response res) async {
    res.sendJson({'message': '$fileName created'});
  }

  Future update(Request req, Response res) async {
    final id = req.params['id'];
    res.sendJson({'message': '$fileName updated \$id'});
  }

  Future delete(Request req, Response res) async {
    final id = req.params['id'];
    res.sendJson({'message': '$fileName deleted \$id'});
  }
}
''';
  }
}

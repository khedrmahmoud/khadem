import 'dart:io';

import '../../bus/command.dart';

class MakeMiddlewareCommand extends KhademCommand {
  @override
  String get name => 'make:middleware';

  @override
  String get description => 'Create a new HTTP middleware class';

  MakeMiddlewareCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Middleware name');
  }

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null) {
      logger.error('Usage: khadem make:middleware --name=<middleware_name>');
      exit(1);
    }

    final className = _toPascalCase(name);
    final fileName = _toSnakeCase(name);

    final dir = Directory('app/http/middleware');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File('${dir.path}/$fileName.dart');

    if (file.existsSync()) {
      logger.error('❌ Middleware "$fileName.dart" already exists!');
      exit(1);
    }

    await file.writeAsString(_template(className));

    logger.info('✅ Middleware "$className" created successfully!');
    exit(0);
  }

  String _template(String className) {
    return '''
import 'package:khadem/khadem_dart.dart';

class $className implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
    // 🛡️ Your middleware logic here

    await next(); // Don't forget to call next!
  };

  @override
  String get name => '$className';

  @override
  MiddlewarePriority get priority => MiddlewarePriority.normal;
}
''';
  }

  String _toPascalCase(String input) {
    return input
        .split(RegExp(r'[_\s-]+'))
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join();
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
        .toLowerCase();
  }
}

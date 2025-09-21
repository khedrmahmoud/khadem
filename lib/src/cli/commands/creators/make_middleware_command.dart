import 'dart:io';

import '../../bus/command.dart';

class MakeMiddlewareCommand extends KhademCommand {
  @override
  String get name => 'make:middleware';

  @override
  String get description => 'Create a new HTTP middleware class with optional folder structure';

  MakeMiddlewareCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Middleware name (e.g., Auth or auth/AuthMiddleware)');
  }

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null) {
      logger.error('Usage: khadem make:middleware --name=MiddlewareName or --name=folder/MiddlewareName');
      exit(1);
    }

    // Parse folder and middleware name
    final parts = name.split('/');
    String folder = '';
    String middlewareName = parts.last;

    if (parts.length > 1) {
      folder = parts.sublist(0, parts.length - 1).join('/');
    }

    // Ensure middleware name ends with 'Middleware'
    if (!middlewareName.endsWith('Middleware')) {
      middlewareName = '${middlewareName}Middleware';
    }

    final className = _toPascalCase(middlewareName);
    final fileName = '${_toSnakeCase(middlewareName.replaceAll('Middleware', ''))}_middleware.dart';
    final relativePath = folder.isEmpty
        ? 'app/http/middleware/$fileName'
        : 'app/http/middleware/$folder/$fileName';

    final file = File(relativePath);

    if (file.existsSync()) {
      logger.error('❌ Middleware "$fileName" already exists!');
      exit(1);
    }

    await file.create(recursive: true);
    await file.writeAsString(_template(className, middlewareName.replaceAll('Middleware', ''), folder));

    logger.info('✅ Middleware "$className" created at "$relativePath"');
    exit(0);
  }

  String _template(String className, String middlewareName, String folder) {
    final namespace = folder.isEmpty ? '' : '$folder/';
    return '''
import 'package:khadem/khadem.dart';

class $className implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
    // 🛡️ ${namespace}$middlewareName middleware logic here

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

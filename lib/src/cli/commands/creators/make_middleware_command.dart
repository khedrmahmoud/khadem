import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeMiddlewareCommand extends KhademCommand {
  @override
  String get name => 'make:middleware';

  @override
  String get description =>
      'Create a new HTTP middleware class with optional folder structure';

  MakeMiddlewareCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Middleware name (e.g., Auth or auth/AuthMiddleware)',
    );
  }

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      logger.error(
        'Usage: khadem make:middleware --name=MiddlewareName or --name=folder/MiddlewareName',
      );
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(name);
    final folder = parts.folder;
    var middlewareName = parts.name;

    // Ensure middleware name ends with 'Middleware'
    middlewareName = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(middlewareName),
      'Middleware',
    );

    final className = middlewareName;
    final fileName =
        '${CliNaming.toSnakeCase(middlewareName.replaceAll('Middleware', ''))}_middleware.dart';
    final relativePath = folder.isEmpty
        ? 'lib/app/http/middleware/$fileName'
        : 'lib/app/http/middleware/$folder/$fileName';

    final file = File(relativePath);

    if (file.existsSync()) {
      logger.error('❌ Middleware "$fileName" already exists!');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(
      _template(
        className,
        middlewareName.replaceAll('Middleware', ''),
        folder,
      ),
    );

    logger.info('✅ Middleware "$className" created at "$relativePath"');
    exitCode = 0;
    return;
  }

  String _template(String className, String middlewareName, String folder) {
    final namespace = folder.isEmpty ? '' : '$folder/';
    return '''
import 'package:khadem/contracts.dart' show Middleware, MiddlewareHandler, MiddlewarePriority;

class $className implements Middleware {
  @override
  MiddlewareHandler get handler => (req, res, next) async {
    // 🛡️ ${namespace}$middlewareName middleware logic here

    await next(); // Don't forget to call next!
  };

  @override
  String get name => '$className';

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}
''';
  }
}

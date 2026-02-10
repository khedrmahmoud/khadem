import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeObserverCommand extends KhademCommand {
  MakeObserverCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Observer name with optional path (e.g. Auth/User)',
    );

    argParser.addOption(
      'model',
      abbr: 'm',
      help: 'Model class name to observe (defaults to the observer base name).',
    );
  }

  @override
  String get name => 'make:observer';

  @override
  String get description => 'Create a new model observer class';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:observer --name=User --model=User');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;

    final rawObserverName = parts.name;
    final observerClassName = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(rawObserverName),
      'Observer',
    );

    final observerBase = observerClassName.replaceAll('Observer', '');

    final modelArg = argResults?['model'] as String?;
    final modelBase = (modelArg == null || modelArg.trim().isEmpty)
        ? observerBase
        : CliNaming.toPascalCase(modelArg.trim());

    final modelClassName = CliNaming.toPascalCase(modelBase);

    final modelFileName = '${CliNaming.toSnakeCase(modelClassName)}.dart';

    final fileName = '${CliNaming.toSnakeCase(observerBase)}_observer.dart';
    final relativePath = folder.isEmpty
        ? 'lib/app/observers/$fileName'
        : 'lib/app/observers/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Observer "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    final modelImport = _buildModelImportPath(
      folder: folder,
      modelFileName: modelFileName,
    );

    await file.create(recursive: true);
    await file.writeAsString(
      _stub(
        observerClassName: observerClassName,
        modelClassName: modelClassName,
        modelImport: modelImport,
      ),
    );

    logger.info('✅ Observer "$observerClassName" created at "$relativePath"');
    exitCode = 0;
  }

  String _buildModelImportPath({
    required String folder,
    required String modelFileName,
  }) {
    final folderSegments = folder.isEmpty
        ? const <String>[]
        : folder.split('/').where((p) => p.isNotEmpty).toList();

    // From lib/app/observers[/<folder>] -> lib/app/models[/<folder>]
    // - observers -> app (../)
    // - observers/<a>/<b> -> app (../../..)
    final upLevels = folderSegments.length + 1;
    final prefix = List.filled(upLevels, '..').join('/');

    final modelFolder = folder.isEmpty ? '' : '$folder/';
    return '$prefix/models/$modelFolder$modelFileName';
  }

  String _stub({
    required String observerClassName,
    required String modelClassName,
    required String modelImport,
  }) {
    return '''
import 'package:khadem/database/orm.dart' show ModelObserver;
import '$modelImport';

class $observerClassName extends ModelObserver<$modelClassName> {
  @override
  void creating($modelClassName model) {
    // Called before the model is created.
  }

  @override
  void created($modelClassName model) {
    // Called after the model is created.
  }

  @override
  void updating($modelClassName model) {
    // Called before the model is updated.
  }

  @override
  void updated($modelClassName model) {
    // Called after the model is updated.
  }

  @override
  bool deleting($modelClassName model) {
    // Return false to cancel deletion.
    return true;
  }

  @override
  void deleted($modelClassName model) {
    // Called after the model is deleted.
  }

  @override
  void retrieved($modelClassName model) {
    // Called after the model is retrieved.
  }
}
''';
  }
}

import 'dart:io';

import '../../bus/command.dart';
import '../../utils/cli_naming.dart';

class MakeModelCommand extends KhademCommand {
  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new model class';

  MakeModelCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Model name with optional path (e.g. Auth/User)',
    );
  }

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:model --name=Auth/User');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final name = parts.name;
    final folder = parts.folder.toLowerCase();

    final className = CliNaming.toPascalCase(name);
    final fileName = CliNaming.toSnakeCase(name);
    final filePath =
        'lib/app/models/${folder.isEmpty ? '' : '$folder/'}$fileName.dart';

    final file = File(filePath);
    if (await file.exists()) {
      logger.error('❌ Model file already exists at $filePath');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);

    final classCode = '''
import 'package:khadem/khadem.dart'
    show KhademModel, RelationDefinition, Timestamps;

class $className extends KhademModel<$className> with Timestamps {
  // Example attribute getters:
  // String? get name => getAttribute('name');
  // String? get email => getAttribute('email');

  @override
  Map<String, dynamic> get casts => {
        'created_at': DateTime,
        'updated_at': DateTime,
      };

  @override
  List<String> get fillable => [
        // 'name',
        // 'email',
        'created_at',
        'updated_at',
      ];

  @override
  List<String> get hidden => [
        // 'password',
      ];

  @override
  Map<String, dynamic> get appends => {
        // 'name_upper': () => (getAttribute('name') as String?)?.toUpperCase(),
      };

  @override
  Map<String, RelationDefinition> get definedRelations => {
        // 'posts': hasMany<Post>(
        //   foreignKey: 'user_id',
        //   relatedTable: 'posts',
        //   factory: () => Post(),
        // ),
      };

  @override
  $className newFactory(Map<String, dynamic> data) {
    return $className()..fromJson(data);
  }
}
''';

    await file.writeAsString(classCode.trim());
    logger.info('✅ Model "$className" created successfully at $filePath');
    exitCode = 0;
    return;
  }
}

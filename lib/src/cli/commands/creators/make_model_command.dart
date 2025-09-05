import 'dart:io';

import '../../bus/command.dart';

class MakeModelCommand extends KhademCommand {
  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new model class';

  MakeModelCommand({required super.logger}) {
    argParser.addOption('name',
        abbr: 'n', help: 'Model name with optional path (e.g. Auth/User)',);
  }

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:model --name=Auth/User');
      exit(1);
    }

    final normalized = input.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final name = parts.last;
    final folderParts = parts.sublist(0, parts.length - 1);
    final folder = folderParts.map((e) => e.toLowerCase()).join('/');

    final className = _toPascalCase(name);
    final fileName = _toSnakeCase(name);
    final filePath = 'app/models/${folder.isEmpty ? '' : '$folder/'}$fileName.dart';

    final file = File(filePath);
    if (await file.exists()) {
      logger.error('❌ Model file already exists at $filePath');
      exit(1);
    }

    await file.create(recursive: true);

    const imports = '''
import 'package:khadem/khadem_dart.dart' show KhademModel, RelationDefinition, HasRelationships, Timestamps;
''';

    final classCode = '''
$imports

class $className extends KhademModel<$className> with Timestamps, HasRelationships {
  $className({int? id}) {
    this.id = id;
  }

  // ✅ Add your fields here
  // String? name;
  // int? age;

  @override
  List<String> get fillable => [];

  @override
  List<String> get hidden => [];

  @override
  List<String> get appends => [];

  @override
  Map<String, Type> get casts => {};

  @override
  getField(String key) {
    return switch (key) {
      'id' => id,
      // 'name' => name,
      _ => null
    };
  }

  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      // case 'name':
      //   name = value;
      //   break;
    }
  }

  @override
  Map<String, RelationDefinition> get relations => {
    // 'profile': hasOne(...),
    // 'posts': hasMany(...),
  };

    @override
    $className newFactory(Map<String, dynamic> data) => $className()..fromJson(data);
    
  }
''';

    await file.writeAsString(classCode.trim());
    logger.info('✅ Model "$className" created successfully at $filePath');
    exit(0);
  }

  String _toPascalCase(String input) {
    if (input.isEmpty) return input;
    return input.split('_').map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1).toLowerCase()).join('');
  }

  String _toSnakeCase(String input) {
    if (input.isEmpty) return input;
    return input.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}').toLowerCase();
  }
}

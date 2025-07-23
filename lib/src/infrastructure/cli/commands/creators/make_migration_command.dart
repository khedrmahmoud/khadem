import 'dart:io';
import '../../bus/command.dart';

class MakeMigrationCommand extends KhademCommand {
  MakeMigrationCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Table name');
  }

  @override
  String get name => 'make:migration';

  @override
  String get description => 'Create a new migration file and update the registry.';

  @override
  Future<void> handle(List<String> args) async {
    final tableName = argResults?['name'] as String?;
    if (tableName == null || tableName.trim().isEmpty) {
      logger.error('❌ Usage: dart run khadem make:migration --name=likes');
      exit(1);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final migrationName = 'create_${tableName}_table';
    final className = _toClassName(migrationName);
    final file = File('database/migrations/${timestamp}_$migrationName.dart');

    await file.create(recursive: true);
    await file.writeAsString(_migrationStub(className, tableName));

    logger.info('✅ Migration created: ${file.path}');

    await _updateMigrationsFile();

    logger.info('🔄 migrations.dart updated successfully.');
    exit(0);
  }

  String _toClassName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join();
  }

  String _migrationStub(String className, String tableName) {
    return '''
import 'package:khadem/khadem_dart.dart' show MigrationFile;

class $className extends MigrationFile {
  @override
  Future<void> up(builder) async {
    builder.create('$tableName', (table) {
      table.id();
      table.string('name');
      table.timestamps();
    });
  }

  @override
  Future<void> down(builder) async {
    builder.dropIfExists('$tableName');
  }
}
''';
  }

  Future<void> _updateMigrationsFile() async {
    final dir = Directory('database/migrations');
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('migrations.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final buffer = StringBuffer();
    buffer.writeln("import 'package:khadem/khadem_dart.dart';\n");

    final classNames = <String>[];

    for (final file in files) {
      final fileName = file.uri.pathSegments.last;
      final className = _toClassName(fileName.replaceAll('.dart', '').split('_').skip(1).join('_'));
      classNames.add(className);
      buffer.writeln("import '$fileName';");
    }

    buffer.writeln('\nList<MigrationFile> migrations = <MigrationFile>[');
    for (final className in classNames) {
      buffer.writeln('  $className(),');
    }
    buffer.writeln('];');

    final output = File('database/migrations/migrations.dart');
    await output.writeAsString(buffer.toString());
  }
}

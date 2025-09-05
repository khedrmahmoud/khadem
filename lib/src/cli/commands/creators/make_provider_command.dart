import 'dart:io';

import '../../bus/command.dart';

class MakeProviderCommand extends KhademCommand {
  MakeProviderCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Provider name with optional path (e.g. Auth/Event)');
  }

  @override
  String get name => 'make:provider';

  @override
  String get description => 'Create a new service provider';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:provider --name=Auth/Event');
      exit(1);
    }

    final normalized = input.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final name = parts.last;
    final folderParts = parts.sublist(0, parts.length - 1);
    final folder = folderParts.map((e) => e.toLowerCase()).join('/');

    final className = '${_toPascalCase(name)}ServiceProvider';
    final fileName = '${_toSnakeCase(name)}_service_provider.dart';
    final filePath = 'app/providers/${folder.isEmpty ? '' : '$folder/'}$fileName';

    final file = File(filePath);
    if (await file.exists()) {
      logger.error('❌ Provider file already exists at $filePath');
      exit(1);
    }

    await file.create(recursive: true);

    await file.writeAsString('''
import 'package:khadem/khadem_dart.dart' 
  show ServiceProvider, ContainerInterface, registerSubscribers;

class $className extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    // Optional: put any registration logic here
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    // Optional: put any boot logic here
  }
}
''');

    logger.info('✅ Service provider "$className" created at $filePath');
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

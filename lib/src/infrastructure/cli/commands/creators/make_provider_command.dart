import 'dart:io';

import '../../bus/command.dart';

class MakeProviderCommand extends KhademCommand {
  MakeProviderCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Provider name (e.g., Event)');
  }

  @override
  String get name => 'make:provider';

  @override
  String get description => 'Create a new service provider';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.isEmpty) {
      logger.error('❌ Usage: dart run khadem make:provider --name=Event');
      exit(1);
    }

    final className = '${_capitalize(name)}ServiceProvider';
    final fileName = '${_snakeCase(name)}_service_provider.dart';
    final filePath = 'app/providers/$fileName';

    final file = File(filePath);
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

  String _capitalize(String input) =>
      input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);

  String _snakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst('_', '');
  }
}

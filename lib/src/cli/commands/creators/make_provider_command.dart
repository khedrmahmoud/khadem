import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeProviderCommand extends KhademCommand {
  MakeProviderCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Provider name with optional path (e.g. Auth/Event)',
    );
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
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final name = parts.name;
    final folder = parts.folder.toLowerCase();

    final className = '${CliNaming.toPascalCase(name)}ServiceProvider';
    final fileName = '${CliNaming.toSnakeCase(name)}_service_provider.dart';
    final filePath =
        'lib/app/providers/${folder.isEmpty ? '' : '$folder/'}$fileName';

    final file = File(filePath);
    if (await file.exists()) {
      logger.error('❌ Provider file already exists at $filePath');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);

    await file.writeAsString('''
import 'package:khadem/contracts.dart' show ServiceProvider, ContainerInterface;

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
    exitCode = 0;
    return;
  }
}

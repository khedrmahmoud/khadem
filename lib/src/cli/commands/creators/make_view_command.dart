import 'dart:io';

import '../../bus/command.dart';
import '../../utils/cli_naming.dart';

class MakeViewCommand extends KhademCommand {
  MakeViewCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'View name (e.g. welcome or admin/dashboard)',
    );
  }

  @override
  String get name => 'make:view';

  @override
  String get description => 'Create a new view template in resources/views.';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:view --name=welcome');
      exitCode = 1;
      return;
    }

    final normalized = CliNaming.normalizePathInput(input);
    final segments = normalized
        .split('/')
        .where((s) => s.trim().isNotEmpty)
        .map(CliNaming.toSnakeCase)
        .toList();

    final viewName = segments.join('/');
    final filePath = 'resources/views/$viewName.khdm.html';

    final file = File(filePath);
    if (await file.exists()) {
      logger.error('❌ View already exists at $filePath');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString('''
<!-- Khadem view: $viewName -->
<div>
  <h1>$viewName</h1>
</div>
'''
        .trim(),);

    logger.info('✅ View "$viewName" created at $filePath');
    exitCode = 0;
  }
}

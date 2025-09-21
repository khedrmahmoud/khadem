import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:khadem/src/cli/command_registry.dart';
import 'package:khadem/src/cli/commands/version_command.dart';
import 'package:khadem/src/core/logging/logger.dart';
import 'package:khadem/src/core/logging/logging_writers/console_writer.dart';

void main(List<String> args) async {
  final logger = Logger();
  logger.addHandler(ConsoleLogHandler());

  // Handle --version flag before command runner
  if (args.contains('--version') || args.contains('-v')) {
    final versionCommand = VersionCommand(logger: logger);
    await versionCommand.handle([]);
    exit(0);
  }

  final registry = CommandRegistry(logger);

  // Auto-discover custom commands from the current project
  final currentDir = Directory.current.path;
  await registry.autoDiscoverCommands(currentDir);

  final runner = CommandRunner('khadem', 'Khadem Dart CLI');

  // Add all commands (core + custom)
  for (final command in registry.commands) {
    runner.addCommand(command);
  }

  try {
    await runner.run(args);
  } catch (e) {
    logger.error('❌ Error: $e');
    exit(1);
  }
  exit(0);
}

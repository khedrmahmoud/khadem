import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:khadem/src/cli/command_registry.dart';
import 'package:khadem/src/cli/commands/commands_command.dart';
import 'package:khadem/src/cli/commands/version_command.dart';
import 'package:khadem/src/core/logging/logger.dart';
import 'package:khadem/src/core/logging/logging_writers/console_writer.dart';

void main(List<String> args) async {
  final logger = Logger();
  logger.addHandler(ConsoleLogHandler());

  // Handle --version flag before command runner
  if (args.length == 1 &&
      (args.first == '--version' || args.first == '-v' || args.first == '-V')) {
    final versionCommand = VersionCommand(logger: logger);
    await versionCommand.handle([]);
    exitCode = 0;
    return;
  }

  final registry = CommandRegistry(logger);

  // Auto-discover custom commands from the current project
  final currentDir = Directory.current.path;
  await registry.autoDiscoverCommands(currentDir);

  final runner = CommandRunner('khadem', 'Khadem Dart CLI');

  runner
      .addCommand(CommandsCommand(logger: logger, commands: registry.commands));

  // Add all commands (core + custom)
  for (final command in registry.commands) {
    runner.addCommand(command);
  }

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    logger.error('❌ ${e.message}');
    logger.info('');
    logger.info(e.usage);

    exitCode = 64;
    return;
  } catch (e) {
    logger.error('❌ Error: $e');
    exitCode = 1;
    return;
  }
}

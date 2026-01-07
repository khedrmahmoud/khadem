import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/logging/logger.dart';
import '../core/logging/logging_writers/console_writer.dart';
import 'bus/command.dart';
import 'command_registry.dart';
import 'command_bootstrapper.dart';
import 'commands/commands_command.dart';
import 'commands/version_command.dart';

/// Shared CLI entry so both:
/// - the package executable (bin/khadem.dart)
/// - a project-local delegate (bin/khadem_cli.dart)
/// can run the same CLI consistently.
Future<int> runKhademCli(
  List<String> args, {
  Logger? logger,
  Future<void> Function()? bootstrapKernel,
}) async {
  final resolvedLogger = logger ?? (Logger()..addHandler(ConsoleLogHandler()));

  // Handle --version flag before command runner
  if (args.length == 1 &&
      (args.first == '--version' || args.first == '-v' || args.first == '-V')) {
    final versionCommand = VersionCommand(logger: resolvedLogger);
    await versionCommand.handle([]);
    return 0;
  }

  final registry = CommandRegistry(resolvedLogger);

  final runner = CommandRunner('khadem', 'Khadem Dart CLI');

  runner.addCommand(
    CommandsCommand(
      logger: resolvedLogger,
      commands: registry.commands,
    ),
  );

  // Add all commands (core + custom)
  for (final command in registry.commands) {
    runner.addCommand(command);
  }

  // Conditionally bootstrap only when needed.
  final commandName = _extractCommandName(args);
  if (commandName != null) {
    final command = runner.commands[commandName];
    if (command is KhademCommand && command.requiresKernelBootstrap) {
      try {
        if (bootstrapKernel != null) {
          await bootstrapKernel();
        } else {
          await CommandBootstrapper.register();
          await CommandBootstrapper.boot();
        }
      } catch (e, stack) {
        resolvedLogger.error('❌ Bootstrap failed: $e');
        resolvedLogger.debug(stack.toString());
        return 1;
      }
    }
  }

  try {
    await runner.run(args);
    return exitCode;
  } on UsageException catch (e) {
    resolvedLogger.error('❌ ${e.message}');
    resolvedLogger.info('');
    resolvedLogger.info(e.usage);
    return 64;
  } catch (e) {
    resolvedLogger.error('❌ Error: $e');
    return 1;
  }
}

String? _extractCommandName(List<String> args) {
  for (final arg in args) {
    if (arg == '--') return null;
    if (!arg.startsWith('-')) return arg;
  }
  return null;
}

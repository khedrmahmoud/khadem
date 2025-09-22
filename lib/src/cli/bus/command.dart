import 'dart:async';

import 'package:args/command_runner.dart';

import '../../core/logging/logger.dart';

/// Base class for all CLI commands in Khadem.
abstract class KhademCommand extends Command<void> {
  final Logger logger;
  int exitCode = 0;

  KhademCommand({required this.logger});

  /// Called automatically before executing the command.
  /// You can override to do pre-validation or setup.
  Future<void> handle(List<String> args);

  @override
  Future<void> run() async {
    try {
      await handle(argResults!.arguments);
    } catch (e, stack) {
      logger.error('❌ Command failed: $e');
      logger.debug(stack.toString());
    }
    // exit(exitCode);
  }
}

/// Handler interface for processing commands.
abstract class CommandHandler<T extends KhademCommand> {
  /// Handles the execution of a command.
  FutureOr<void> handle(T command);
}

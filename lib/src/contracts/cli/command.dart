import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:khadem/contracts.dart' show LoggerContract;

/// Base class for all CLI commands in Khadem.
abstract class KhademCommand extends Command<void> {
  final LoggerContract logger;
  int exitCode = 0;

  KhademCommand({required this.logger});

  /// Called automatically before executing the command.
  /// You can override to do pre-validation or setup.
  Future<void> handle(List<String> args);

  void succeed([int code = 0]) {
    exitCode = code;
    io.exitCode = code;
  }

  void fail(String message, {int code = 1}) {
    exitCode = code;
    io.exitCode = code;
    logger.error(message);
  }

  @override
  Future<void> run() async {
    try {
      await handle(argResults?.arguments ?? const []);
    } catch (e, stack) {
      if (exitCode == 0) {
        exitCode = 1;
      }
      io.exitCode = exitCode;
      logger.error('❌ Command failed: $e');
      logger.debug(stack.toString());
    }
    io.exitCode = exitCode;
  }
}

/// Handler interface for processing commands.
abstract class CommandHandler<T extends KhademCommand> {
  /// Handles the execution of a command.
  FutureOr<void> handle(T command);
}

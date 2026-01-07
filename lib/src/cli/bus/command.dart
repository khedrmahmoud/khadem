import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';

import '../../core/logging/logger.dart';

/// Base class for all CLI commands in Khadem.
abstract class KhademCommand extends Command<void> {
  final Logger logger;
  int exitCode = 0;

  KhademCommand({required this.logger});

  /// Whether this command needs the application/kernel bootstrapped.
  ///
  /// When true, the CLI will run the bootstrap callback once before executing
  /// the command (either the project Kernel bootstrap, or the CLI bootstrapper
  /// fallback).
  bool get requiresKernelBootstrap => false;

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

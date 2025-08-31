import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:khadem/src/cli/command_registry.dart';
import 'package:khadem/src/core/logging/logger.dart';
import 'package:khadem/src/support/logging_writers/console_writer.dart';

void main(List<String> args) async {
  final logger = Logger();
  logger.addHandler(ConsoleLogHandler());

  final registry = CommandRegistry(logger);

  final runner = CommandRunner('khadem', 'Khadem Dart CLI');

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

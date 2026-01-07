import 'dart:io';

import '../bus/command.dart';

class LogsClearCommand extends KhademCommand {
  LogsClearCommand({required super.logger});

  @override
  String get name => 'logs:clear';

  @override
  String get description => 'Clear log files in storage/logs.';

  @override
  Future<void> handle(List<String> args) async {
    final logsDir = Directory('storage/logs');
    if (!await logsDir.exists()) {
      logger.warning('No logs directory found at storage/logs');
      exitCode = 0;
      return;
    }

    try {
      var deleted = 0;
      await for (final entity in logsDir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.log')) {
          await entity.delete();
          deleted++;
        }
      }

      if (deleted == 0) {
        logger.info('No .log files to delete in storage/logs');
      } else {
        logger.info('✅ Deleted $deleted log file(s)');
      }

      exitCode = 0;
    } catch (e) {
      logger.error('❌ Failed to clear logs: $e');
      exitCode = 1;
    }
  }
}

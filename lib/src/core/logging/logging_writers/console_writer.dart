import 'dart:convert';
import 'dart:io';

import 'package:khadem/src/contracts/logging/log_handler.dart';
import 'package:khadem/src/contracts/logging/log_level.dart';

/// Console-based log handler.
class ConsoleLogHandler implements LogHandler {
  final bool _colorize;
  final LogLevel _minimumLevel;

  ConsoleLogHandler({
    bool colorize = true,
    LogLevel minimumLevel = LogLevel.debug,
  })  : _colorize = colorize,
        _minimumLevel = minimumLevel;

  @override
  LogLevel get minimumLevel => _minimumLevel;

  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    if (!level.isAtLeast(_minimumLevel)) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();

    var logMessage = '[$timestamp] [$levelStr] $message';

    if (_colorize) {
      logMessage = _colorize ? _colorizeMessage(level, logMessage) : logMessage;
    }

    stdout.writeln(logMessage);

    if (context != null) {
      stdout.writeln('Context: ${jsonEncode(context)}');
    }

    if (stackTrace != null) {
      stdout.writeln('Stack Trace:\n$stackTrace');
    }
  }

  String _colorizeMessage(LogLevel level, String message) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[37m$message\x1B[0m'; // White
      case LogLevel.info:
        return '\x1B[32m$message\x1B[0m'; // Green
      case LogLevel.warning:
        return '\x1B[33m$message\x1B[0m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m$message\x1B[0m'; // Red
      case LogLevel.critical:
        return '\x1B[35m$message\x1B[0m'; // Magenta
    }
  }

  @override
  void close() {
    // No resources to close for console handler
  }
}

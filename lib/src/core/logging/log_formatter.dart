import 'package:khadem/khadem.dart' show LogLevel;

/// Interface for log message formatters.
/// Responsible for formatting log entries into strings.
abstract class LogFormatter {
  /// Formats a log entry into a string.
  String format(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  });
}

/// JSON formatter for structured logging.
class JsonLogFormatter implements LogFormatter {
  @override
  String format(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) {
    final logEntry = {
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'level': level.name.toUpperCase(),
      'message': message,
      if (context != null) 'context': context,
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };

    return logEntry.toString(); // In a real implementation, use jsonEncode
  }
}

/// Text formatter for human-readable logging.
class TextLogFormatter implements LogFormatter {
  final bool _includeTimestamp;
  final bool _includeLevel;

  TextLogFormatter({
    bool includeTimestamp = true,
    bool includeLevel = true,
  })  : _includeTimestamp = includeTimestamp,
        _includeLevel = includeLevel;

  @override
  String format(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    DateTime? timestamp,
  }) {
    final buffer = StringBuffer();

    if (_includeTimestamp) {
      final time = timestamp ?? DateTime.now();
      buffer.write('[${time.toIso8601String()}] ');
    }

    if (_includeLevel) {
      buffer.write('[${level.name.toUpperCase()}] ');
    }

    buffer.write(message);

    if (context != null && context.isNotEmpty) {
      buffer.write('\nContext: $context');
    }

    if (stackTrace != null) {
      buffer.write('\nStack Trace:\n$stackTrace');
    }

    return buffer.toString();
  }
}

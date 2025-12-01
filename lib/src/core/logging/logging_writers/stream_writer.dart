import 'dart:async';

import 'package:khadem/khadem.dart' show LogHandler, LogLevel;

/// A log handler that writes log entries to a Stream.
/// Useful for real-time log monitoring or piping logs to other systems.
class StreamLogHandler implements LogHandler {
  final StreamController<LogEntry> _controller;

  StreamLogHandler({bool sync = false})
      : _controller = StreamController<LogEntry>.broadcast(sync: sync);

  /// The stream of log entries.
  Stream<LogEntry> get stream => _controller.stream;

  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    if (!_controller.isClosed) {
      _controller.add(LogEntry(
        level: level,
        message: message,
        context: context,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  void close() {
    _controller.close();
  }
}

/// Represents a single log entry.
class LogEntry {
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.context,
    this.stackTrace,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.toString(),
      'message': message,
      'context': context,
      'stackTrace': stackTrace?.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

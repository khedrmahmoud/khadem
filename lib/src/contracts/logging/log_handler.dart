import 'log_level.dart';

/// Interface for log handlers.
abstract class LogHandler {
  /// The minimum log level this handler should process.
  LogLevel get minimumLevel;

  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  });
  void close();
}

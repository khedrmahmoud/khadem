
import '../../infrastructure/logging/log_level.dart';

/// Interface for log handlers.
abstract class LogHandler {
  void log(LogLevel level, String message,
      {Map<String, dynamic>? context, StackTrace? stackTrace});
  void close();
}

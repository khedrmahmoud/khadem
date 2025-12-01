import 'package:khadem/khadem.dart' show LogHandler, LogLevel;

/// A log handler that delegates logging to a callback function.
/// Useful for integrating with external services or testing.
class CallbackLogHandler implements LogHandler {
  final void Function(LogLevel level, String message, Map<String, dynamic>? context, StackTrace? stackTrace) _callback;

  CallbackLogHandler(this._callback);

  @override
  void log(LogLevel level, String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    _callback(level, message, context, stackTrace);
  }

  @override
  void close() {}
}

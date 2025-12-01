import 'package:khadem/khadem.dart' show LogLevel;
import '../../application/khadem.dart';

/// A static facade for the logging system.
///
/// Provides easy access to logging functionality without injecting the Logger service.
///
/// Example:
/// ```dart
/// Log.info('User logged in', context: {'id': 1});
/// Log.channel('audit').warning('Unauthorized access');
/// ```
class Log {
  /// Logs a debug message.
  static void debug(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    Khadem.logger.debug(
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs an info message.
  static void info(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    Khadem.logger.info(
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs a warning message.
  static void warning(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    Khadem.logger.warning(
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs an error message.
  static void error(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    Khadem.logger.error(
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs a critical message.
  static void critical(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    Khadem.logger.critical(
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Creates a logger proxy for a specific channel.
  static ChannelLogger channel(String name) {
    return ChannelLogger(name);
  }

  static final Map<String, Stopwatch> _timers = {};

  /// Starts a timer with the given label.
  static void time(String label) {
    _timers[label] = Stopwatch()..start();
  }

  /// Stops the timer with the given label and logs the elapsed time.
  static void timeEnd(String label, {LogLevel level = LogLevel.debug}) {
    if (_timers.containsKey(label)) {
      final stopwatch = _timers[label]!;
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      _timers.remove(label);
      
      Khadem.logger.log(
        level,
        '$label: ${elapsed}ms',
        context: {'duration_ms': elapsed},
      );
    }
  }
}

/// Helper class for channel-specific logging.
class ChannelLogger {
  final String _channel;

  ChannelLogger(this._channel);

  void debug(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    Khadem.logger.debug(message, context: context, stackTrace: stackTrace, channel: _channel);
  }

  void info(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    Khadem.logger.info(message, context: context, stackTrace: stackTrace, channel: _channel);
  }

  void warning(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    Khadem.logger.warning(message, context: context, stackTrace: stackTrace, channel: _channel);
  }

  void error(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    Khadem.logger.error(message, context: context, stackTrace: stackTrace, channel: _channel);
  }

  void critical(String message, {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    Khadem.logger.critical(message, context: context, stackTrace: stackTrace, channel: _channel);
  }
}

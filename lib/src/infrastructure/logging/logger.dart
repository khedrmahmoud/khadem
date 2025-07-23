import '../../contracts/config/config_contract.dart';
import '../../contracts/logging/log_handler.dart';
import 'log_level.dart';
import '../../support/logging_writers/console_writer.dart';
import '../../support/logging_writers/file_writer.dart';

/// Main logger class that manages multiple log handlers and channels.
class Logger {
  final Map<String, List<LogHandler>> _channels = {};
  LogLevel _minimumLevel;
  String _defaultChannel = 'app';

  Logger({LogLevel minimumLevel = LogLevel.debug})
      : _minimumLevel = minimumLevel;

  void loadFromConfig(ConfigInterface config, {String channel = "app"}) {
    _minimumLevel =
        _parseLevel(config.get<String>('logging.minimum_level', 'debug')!);
    _defaultChannel = config.get<String>('logging.default', channel) ?? channel;
    final handlers = config.get<Map<String, dynamic>>('logging.handlers', {})!;

    if (handlers['file']?['enabled'] == true) {
      addHandler(
        FileLogHandler(
          filePath: handlers['file']['path'] ?? 'storage/logs/app.log',
          formatJson: handlers['file']['format_json'] ?? true,
          rotateOnSize: handlers['file']['rotate_on_size'] ?? true,
          rotateDaily: handlers['file']['rotate_daily'] ?? false,
          maxFileSizeBytes: handlers['file']['max_size'] ?? 5 * 1024 * 1024,
          maxBackupCount: handlers['file']['max_backups'] ?? 5,
        ),
      );
    }

    if (handlers['console']?['enabled'] == true) {
      addHandler(
        ConsoleLogHandler(
          colorize: handlers['console']['colorize'] ?? true,
        ),
      );
    }
  }

  static LogLevel _parseLevel(String value) {
    switch (value.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      case 'critical':
        return LogLevel.critical;
      default:
        return LogLevel.debug;
    }
  }

  /// Adds a log handler to a specific channel.
  void addHandler(LogHandler handler, {String channel = 'app'}) {
    _channels[channel] ??= [];
    _channels[channel]!.add(handler);
  }

  /// Sets the default channel for logging.
  void setDefaultChannel(String channel) {
    _defaultChannel = channel;
  }

  /// Logs a debug message.
  void debug(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel}) {
    _log(LogLevel.debug, message,
        context: context, stackTrace: stackTrace, channel: channel);
  }

  /// Logs an info message.
  void info(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel}) {
    _log(LogLevel.info, message,
        context: context, stackTrace: stackTrace, channel: channel);
  }

  /// Logs a warning message.
  void warning(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel}) {
    _log(LogLevel.warning, message,
        context: context, stackTrace: stackTrace, channel: channel);
  }

  /// Logs an error message.
  void error(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel}) {
    _log(LogLevel.error, message,
        context: context, stackTrace: stackTrace, channel: channel);
  }

  /// Logs a critical message.
  void critical(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel}) {
    _log(LogLevel.critical, message,
        context: context, stackTrace: stackTrace, channel: channel);
  }

  /// Internal method to log a message with a specific level.
  void _log(LogLevel level, String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel}) {
    if (level.index < _minimumLevel.index) {
      return;
    }

    final targetChannel = channel ?? _defaultChannel;
    final handlers = _channels[targetChannel] ?? [];

    for (final handler in handlers) {
      handler.log(level, message, context: context, stackTrace: stackTrace);
    }
  }

  /// Closes all log handlers.
  void close() {
    for (final handlers in _channels.values) {
      for (final handler in handlers) {
        handler.close();
      }
    }
  }
}

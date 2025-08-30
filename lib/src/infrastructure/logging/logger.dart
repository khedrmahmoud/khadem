import '../../contracts/config/config_contract.dart';
import '../../contracts/logging/log_handler.dart';
import '../../contracts/logging/log_level.dart';
import '../../contracts/logging/logger_contract.dart';
import '../../support/logging_writers/console_writer.dart';
import '../../support/logging_writers/file_writer.dart';

/// Main logger class that manages multiple log handlers and channels.
class Logger implements LoggerContract {
  final Map<String, List<LogHandler>> _channels = {};
  LogLevel _minimumLevel;
  String _defaultChannel = 'app';

  @override
  LogLevel get minimumLevel => _minimumLevel;

  @override
  set minimumLevel(LogLevel level) => _minimumLevel = level;

  @override
  String get defaultChannel => _defaultChannel;

  Logger({LogLevel minimumLevel = LogLevel.debug})
      : _minimumLevel = minimumLevel;

  @override
  void loadFromConfig(ConfigInterface config, {String channel = "app"}) {
    _minimumLevel = LogLevel.fromString(
      config.get<String>('logging.minimum_level', 'debug')!,
    );
    _defaultChannel = config.get<String>('logging.default', channel) ?? channel;
    final handlers = config.get<Map<String, dynamic>>('logging.handlers', {})!;
    final fileConfig = handlers['file'] as Map<String, dynamic>?;
    final consoleConfig = handlers['console'] as Map<String, dynamic>?;

    if (fileConfig?['enabled'] == true) {
      addHandler(
        FileLogHandler(
          filePath: fileConfig!['path']?.toString() ?? 'storage/logs/app.log',
          formatJson: fileConfig['format_json'] as bool? ?? true,
          rotateOnSize: fileConfig['rotate_on_size'] as bool? ?? true,
          rotateDaily: fileConfig['rotate_daily'] as bool? ?? false,
          maxFileSizeBytes: fileConfig['max_size'] as int? ?? 5 * 1024 * 1024,
          maxBackupCount: fileConfig['max_backups'] as int? ?? 5,
        ),
      );
    }

    if (consoleConfig?['enabled'] == true) {
      addHandler(
        ConsoleLogHandler(
          colorize: consoleConfig!['colorize'] as bool? ?? true,
        ),
      );
    }
  }

  /// Adds a log handler to a specific channel.
  @override
  void addHandler(LogHandler handler, {String channel = 'app'}) {
    _channels[channel] ??= [];
    _channels[channel]!.add(handler);
  }

  /// Sets the default channel for logging.
@override
  void setDefaultChannel(String channel) {
    _defaultChannel = channel;
  }

  /// Logs a debug message.
  @override
  void debug(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel,}) {
    _log(LogLevel.debug, message,
        context: context, stackTrace: stackTrace, channel: channel,);
  }

  /// Logs an info message.
  @override
  void info(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel,}) {
    _log(LogLevel.info, message,
        context: context, stackTrace: stackTrace, channel: channel,);
  }

  /// Logs a warning message.
  @override
  void warning(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel,}) {
    _log(LogLevel.warning, message,
        context: context, stackTrace: stackTrace, channel: channel,);
  }

  /// Logs an error message.
@override
  void error(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel,}) {
    _log(LogLevel.error, message,
        context: context, stackTrace: stackTrace, channel: channel,);
  }

  /// Logs a critical message.
@override
 void critical(String message,
      {Map<String, dynamic>? context,
      StackTrace? stackTrace,
      String? channel,}) {
    _log(LogLevel.critical, message,
        context: context, stackTrace: stackTrace, channel: channel,);
  }

  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    if (!level.isAtLeast(_minimumLevel)) {
      return;
    }

    final targetChannel = channel ?? _defaultChannel;
    final handlers = _channels[targetChannel] ?? [];

    for (final handler in handlers) {
      handler.log(level, message, context: context, stackTrace: stackTrace);
    }
  }

  /// Internal method to log a message with a specific level.
  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    log(level, message,
        context: context, stackTrace: stackTrace, channel: channel,);
  }

  /// Closes all log handlers.
  @override
  void close() {
    for (final handlers in _channels.values) {
      for (final handler in handlers) {
        handler.close();
      }
    }
  }
}

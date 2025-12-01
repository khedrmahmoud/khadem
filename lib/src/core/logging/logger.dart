import 'package:khadem/khadem.dart'
    show LoggerContract, ConfigInterface, LogHandler, LogLevel;

import 'log_channel_manager.dart';
import 'logging_configuration.dart';

/// Advanced logger implementation that provides structured logging capabilities.
/// This logger supports multiple channels, configurable handlers, and proper separation of concerns.
///
/// Features:
/// - Multiple log channels for different parts of the application
/// - Configurable log levels and filtering
/// - Support for structured logging with context
/// - Pluggable log handlers (console, file, etc.)
/// - Automatic configuration loading from application config
///
/// Example usage:
/// ```dart
/// final logger = Logger();
/// logger.info('Application started', context: {'version': '1.0.0'});
/// logger.error('Database connection failed', context: {'error': e.toString()});
/// ```
class Logger implements LoggerContract {
  final LogChannelManager _channelManager;
  LogLevel _minimumLevel;
  String _defaultChannel;

  /// Creates a new logger instance.
  ///
  /// [minimumLevel] - The minimum log level to process (default: debug)
  Logger({
    LogLevel minimumLevel = LogLevel.debug,
    LogChannelManager? channelManager,
  })  : _channelManager = channelManager ?? LogChannelManager(),
        _minimumLevel = minimumLevel,
        _defaultChannel = 'app';

  @override
  LogLevel get minimumLevel => _minimumLevel;

  @override
  set minimumLevel(LogLevel level) => _minimumLevel = level;

  @override
  String get defaultChannel => _defaultChannel;

  /// Loads logger configuration from the application config system.
  ///
  /// This method reads logging configuration from the provided config and
  /// sets up the appropriate handlers for each channel.
  ///
  /// [config] - The application configuration interface
  /// [channel] - The default channel name (optional)
  @override
  void loadFromConfig(ConfigInterface config, {String channel = "app"}) {
    final loggingConfig = LoggingConfiguration(config);

    // Validate configuration
    loggingConfig.validate();

    // Apply configuration
    _minimumLevel = loggingConfig.minimumLevel;
    _defaultChannel = loggingConfig.defaultChannel;

    // Clear existing handlers and add new ones
    _channelManager.clearAll();
    for (final handler in loggingConfig.handlers) {
      _channelManager.addHandler(handler, channel: _defaultChannel);
    }
  }

  /// Adds a log handler to a specific channel.
  ///
  /// [handler] - The log handler to add
  /// [channel] - The channel name (default: 'app')
  @override
  void addHandler(LogHandler handler, {String channel = 'app'}) {
    _channelManager.addHandler(handler, channel: channel);
  }

  /// Sets the default channel for logging operations.
  ///
  /// [channel] - The name of the default channel
  @override
  void setDefaultChannel(String channel) {
    _defaultChannel = channel;
  }

  /// Logs a debug message.
  ///
  /// [message] - The log message
  /// [context] - Optional structured context data
  /// [stackTrace] - Optional stack trace
  /// [channel] - Optional channel name (uses default if not specified)
  @override
  void debug(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    _log(
      LogLevel.debug,
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs an info message.
  ///
  /// [message] - The log message
  /// [context] - Optional structured context data
  /// [stackTrace] - Optional stack trace
  /// [channel] - Optional channel name (uses default if not specified)
  @override
  void info(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    _log(
      LogLevel.info,
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs a warning message.
  ///
  /// [message] - The log message
  /// [context] - Optional structured context data
  /// [stackTrace] - Optional stack trace
  /// [channel] - Optional channel name (uses default if not specified)
  @override
  void warning(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    _log(
      LogLevel.warning,
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs an error message.
  ///
  /// [message] - The log message
  /// [context] - Optional structured context data
  /// [stackTrace] - Optional stack trace
  /// [channel] - Optional channel name (uses default if not specified)
  @override
  void error(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    _log(
      LogLevel.error,
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs a critical message.
  ///
  /// [message] - The log message
  /// [context] - Optional structured context data
  /// [stackTrace] - Optional stack trace
  /// [channel] - Optional channel name (uses default if not specified)
  @override
  void critical(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    _log(
      LogLevel.critical,
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Logs a message with a specific level.
  ///
  /// [level] - The log level
  /// [message] - The log message
  /// [context] - Optional structured context data
  /// [stackTrace] - Optional stack trace
  /// [channel] - Optional channel name (uses default if not specified)
  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    // We no longer check global minimum level here, as each handler
    // now manages its own minimum level.
    // if (!level.isAtLeast(_minimumLevel)) {
    //   return;
    // }

    final targetChannel = channel ?? _defaultChannel;
    _channelManager.logToChannel(
      targetChannel,
      level,
      message,
      context: context,
      stackTrace: stackTrace,
    );
  }

  /// Internal method to log a message with a specific level.
  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  }) {
    log(
      level,
      message,
      context: context,
      stackTrace: stackTrace,
      channel: channel,
    );
  }

  /// Closes all log handlers and releases resources.
  /// This should be called when the logger is no longer needed.
  @override
  void close() {
    _channelManager.closeAll();
  }
}

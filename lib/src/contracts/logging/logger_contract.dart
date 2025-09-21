import '../config/config_contract.dart';
import 'log_handler.dart';
import 'log_level.dart';

/// Interface for the logger system
abstract class LoggerContract {
  /// Loads logger configuration from the config system
  void loadFromConfig(ConfigInterface config, {String channel = "app"});

  /// Adds a log handler to a specific channel
  void addHandler(LogHandler handler, {String channel = 'app'});

  /// Sets the default channel for logging
  void setDefaultChannel(String channel);

  /// Logs a debug message
  void debug(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  });

  /// Logs an info message
  void info(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  });

  /// Logs a warning message
  void warning(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  });

  /// Logs an error message
  void error(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  });

  /// Logs a critical message
  void critical(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  });

  /// Log a message with a specific level
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? channel,
  });

  /// Gets the minimum log level
  LogLevel get minimumLevel;

  /// Sets the minimum log level
  set minimumLevel(LogLevel level);

  /// Gets the default channel
  String get defaultChannel;

  /// Closes all log handlers
  void close();
}

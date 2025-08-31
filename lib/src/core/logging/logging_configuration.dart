import '../../contracts/config/config_contract.dart';
import '../../contracts/logging/log_handler.dart';
import '../../contracts/logging/log_level.dart';
import '../../support/logging_writers/console_writer.dart';
import '../../support/logging_writers/file_writer.dart';

/// Configuration manager for the logging system.
/// Handles loading and parsing logging configuration from the application config.
class LoggingConfiguration {
  final ConfigInterface _config;

  LoggingConfiguration(this._config);

  /// Gets the minimum log level from configuration.
  LogLevel get minimumLevel {
    final levelStr = _config.get<String>('logging.minimum_level', 'debug')!;
    return LogLevel.fromString(levelStr);
  }

  /// Gets the default logging channel from configuration.
  String get defaultChannel {
    return _config.get<String>('logging.default', 'app') ?? 'app';
  }

  /// Gets the configured log handlers.
  List<LogHandler> get handlers {
    final handlers = <LogHandler>[];
    final handlersConfig = _config.get<Map<String, dynamic>>('logging.handlers', {})!;

    // Configure file handler
    final fileConfig = handlersConfig['file'] as Map<String, dynamic>?;
    if (fileConfig != null && fileConfig['enabled'] == true) {
      handlers.add(_createFileHandler(fileConfig));
    }

    // Configure console handler
    final consoleConfig = handlersConfig['console'] as Map<String, dynamic>?;
    if (consoleConfig != null && consoleConfig['enabled'] == true) {
      handlers.add(_createConsoleHandler(consoleConfig));
    }

    return handlers;
  }

  /// Creates a file log handler from configuration.
  FileLogHandler _createFileHandler(Map<String, dynamic> config) {
    return FileLogHandler(
      filePath: config['path']?.toString() ?? 'storage/logs/app.log',
      formatJson: config['format_json'] as bool? ?? true,
      rotateOnSize: config['rotate_on_size'] as bool? ?? true,
      rotateDaily: config['rotate_daily'] as bool? ?? false,
      maxFileSizeBytes: config['max_size'] as int? ?? 5 * 1024 * 1024,
      maxBackupCount: config['max_backups'] as int? ?? 5,
    );
  }

  /// Creates a console log handler from configuration.
  ConsoleLogHandler _createConsoleHandler(Map<String, dynamic> config) {
    return ConsoleLogHandler(
      colorize: config['colorize'] as bool? ?? true,
    );
  }

  /// Validates the logging configuration.
  /// Throws an exception if the configuration is invalid.
  void validate() {
    try {
      // Test minimum level parsing
      minimumLevel;

      // Test default channel
      final channel = defaultChannel;
      if (channel.isEmpty) {
        throw ArgumentError('Default channel cannot be empty');
      }

      // Test handlers configuration
      handlers;
    } catch (e) {
      throw ArgumentError('Invalid logging configuration: $e');
    }
  }
}

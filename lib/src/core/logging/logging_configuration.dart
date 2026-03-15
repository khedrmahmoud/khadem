import 'package:khadem/contracts.dart'
    show ConfigInterface, LogLevel, LogHandler;

import 'logging_writers/console_writer.dart';
import 'logging_writers/file_writer.dart';

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

  /// Gets the configured log channels and their handlers.
  Map<String, List<LogHandler>> get channels {
    final channels = <String, List<LogHandler>>{};

    // Try new channels configuration first
    final channelsConfig =
        _config.get<Map<String, dynamic>>('logging.channels');

    if (channelsConfig != null) {
      // First pass: create non-stack handlers
      for (final entry in channelsConfig.entries) {
        final name = entry.key;
        final config = entry.value as Map<String, dynamic>;
        final driver = config['driver'] as String?;

        if (driver != 'stack') {
          final handler = _createHandler(driver, config);
          if (handler != null) {
            channels[name] = [handler];
          }
        }
      }

      // Second pass: create stack handlers
      for (final entry in channelsConfig.entries) {
        final name = entry.key;
        final config = entry.value as Map<String, dynamic>;
        final driver = config['driver'] as String?;

        if (driver == 'stack') {
          final includedChannels = (config['channels'] as List).cast<String>();
          final handlers = <LogHandler>[];
          for (final includedName in includedChannels) {
            if (channels.containsKey(includedName)) {
              handlers.addAll(channels[includedName]!);
            }
          }
          channels[name] = handlers;
        }
      }
    } else {
      // Fallback to legacy handlers configuration
      final handlersConfig =
          _config.get<Map<String, dynamic>>('logging.handlers', {});
      if (handlersConfig != null) {
        // Configure file handler
        final fileConfig = handlersConfig['file'] as Map<String, dynamic>?;
        if (fileConfig != null && fileConfig['enabled'] == true) {
          channels['file'] = [_createFileHandler(fileConfig)];
        }

        // Configure console handler
        final consoleConfig =
            handlersConfig['console'] as Map<String, dynamic>?;
        if (consoleConfig != null && consoleConfig['enabled'] == true) {
          channels['console'] = [_createConsoleHandler(consoleConfig)];
        }

        // For legacy config, 'app' channel includes all enabled handlers
        channels['app'] = [
          ...?channels['file'],
          ...?channels['console'],
        ];
      }
    }

    return channels;
  }

  LogHandler? _createHandler(String? driver, Map<String, dynamic> config) {
    switch (driver) {
      case 'single':
      case 'daily':
        return _createFileHandler(config);
      case 'console':
        return _createConsoleHandler(config);
      default:
        return null;
    }
  }

  /// Gets the configured log handlers (Legacy support).
  List<LogHandler> get handlers {
    return channels['app'] ?? [];
  }

  /// Creates a file log handler from configuration.
  FileLogHandler _createFileHandler(Map<String, dynamic> config) {
    final levelStr = config['level'] as String?;
    final level =
        levelStr != null ? LogLevel.fromString(levelStr) : minimumLevel;

    final driver = config['driver'] as String?;
    final isDaily =
        driver == 'daily' || (config['rotate_daily'] as bool? ?? false);

    return FileLogHandler(
      filePath: config['path']?.toString() ?? 'storage/logs/app.log',
      formatJson: config['format_json'] as bool? ?? true,
      rotateOnSize: config['rotate_on_size'] as bool? ?? true,
      rotateDaily: isDaily,
      maxFileSizeBytes: config['max_size'] as int? ?? 5 * 1024 * 1024,
      maxBackupCount: config['max_backups'] as int? ?? 5,
      minimumLevel: level,
    );
  }

  /// Creates a console log handler from configuration.
  ConsoleLogHandler _createConsoleHandler(Map<String, dynamic> config) {
    final levelStr = config['level'] as String?;
    final level =
        levelStr != null ? LogLevel.fromString(levelStr) : minimumLevel;

    return ConsoleLogHandler(
      colorize: config['colorize'] as bool? ?? true,
      minimumLevel: level,
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

      // Test channels configuration
      channels;
    } catch (e) {
      throw ArgumentError('Invalid logging configuration: $e');
    }
  }
}

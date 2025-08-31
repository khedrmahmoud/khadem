# Khadem Logging System

A comprehensive, structured logging system for the Khadem framework with support for multiple channels, configurable handlers, and proper separation of concerns.

## Features

- **Multiple Log Channels**: Organize logs by different parts of your application
- **Configurable Handlers**: Support for console and file logging with customizable formatting
- **Structured Logging**: Log with context data for better debugging and monitoring
- **Log Level Filtering**: Control which log messages are processed based on severity
- **File Rotation**: Automatic log file rotation based on size or time
- **Error Handling**: Robust error handling that prevents logging failures from crashing the application
- **Extensible Architecture**: Easy to add new log handlers and formatters

## Architecture

The logging system is built with clear separation of concerns:

- **`Logger`**: Main logging interface that coordinates all logging operations
- **`LogChannelManager`**: Manages log channels and their associated handlers
- **`LoggingConfiguration`**: Handles loading and parsing logging configuration
- **`LogFormatter`**: Formats log messages (JSON, text, custom)
- **`LogHandler`**: Writes logs to different destinations (console, file, etc.)
- **`LogLevel`**: Defines log severity levels with comparison methods

## Quick Start

### Basic Usage

```dart
import 'package:khadem/src/core/logging/logger.dart';
import 'package:khadem/src/core/logging/log_level.dart';

final logger = Logger();

// Simple logging
logger.info('Application started');
logger.error('Something went wrong');

// Logging with context
logger.debug('User action', context: {
  'userId': 123,
  'action': 'login',
  'timestamp': DateTime.now(),
});

// Logging with stack trace
try {
  riskyOperation();
} catch (e, stackTrace) {
  logger.error('Operation failed', context: {'error': e.toString()}, stackTrace: stackTrace);
}
```

### Configuration

The logger can be configured through the application config system:

```dart
// config/app.dart or similar
return {
  'logging': {
    'minimum_level': 'info',
    'default': 'app',
    'handlers': {
      'console': {
        'enabled': true,
        'colorize': true,
      },
      'file': {
        'enabled': true,
        'path': 'storage/logs/app.log',
        'format_json': true,
        'rotate_on_size': true,
        'max_size': 5242880, // 5MB
        'max_backups': 5,
      },
    },
  },
};
```

### Loading Configuration

```dart
final logger = Logger();
final config = AppConfig(); // Your config implementation

logger.loadFromConfig(config);
```

## Log Levels

The system supports the following log levels (in order of severity):

- **`debug`**: Detailed information for debugging
- **`info`**: General information about application operation
- **`warning`**: Warning messages that indicate potential issues
- **`error`**: Error messages that indicate failures
- **`critical`**: Critical errors that require immediate attention

### Log Level Methods

```dart
// Check if a level meets the minimum requirement
if (LogLevel.warning.isAtLeast(LogLevel.info)) {
  // This will be true
}

// Parse from string
final level = LogLevel.fromString('error');

// Get string representation
print(LogLevel.debug.name); // 'debug'
print(LogLevel.debug.nameUpper); // 'DEBUG'
```

## Channels

Channels allow you to organize logs by different parts of your application:

```dart
final logger = Logger();

// Log to default channel
logger.info('General message');

// Log to specific channel
logger.info('Database operation', channel: 'database');
logger.warning('Cache miss', channel: 'cache');

// Add handlers to specific channels
logger.addHandler(ConsoleLogHandler(), channel: 'api');
logger.addHandler(FileLogHandler(filePath: 'logs/api.log'), channel: 'api');
```

## Handlers

### Console Handler

Outputs logs to the console with optional colorization:

```dart
final consoleHandler = ConsoleLogHandler(
  colorize: true, // Enable colored output
);
```

### File Handler

Writes logs to files with rotation support:

```dart
final fileHandler = FileLogHandler(
  filePath: 'logs/app.log',
  formatJson: true, // JSON format
  rotateOnSize: true, // Rotate when file reaches max size
  rotateDaily: false, // Rotate daily
  maxFileSizeBytes: 5 * 1024 * 1024, // 5MB
  maxBackupCount: 5, // Keep 5 backup files
);
```

## Custom Handlers

Create custom log handlers by implementing the `LogHandler` interface:

```dart
class CustomLogHandler implements LogHandler {
  @override
  void log(LogLevel level, String message,
      {Map<String, dynamic>? context, StackTrace? stackTrace}) {
    // Your custom logging logic here
    sendToExternalService(level, message, context);
  }

  @override
  void close() {
    // Clean up resources
  }
}
```

## Formatters

### Text Formatter

Human-readable text format:

```dart
final formatter = TextLogFormatter(
  includeTimestamp: true,
  includeLevel: true,
);
```

### JSON Formatter

Structured JSON format for machine processing:

```dart
final formatter = JsonLogFormatter();
```

### Custom Formatters

```dart
class CustomFormatter implements LogFormatter {
  @override
  String format(LogLevel level, String message,
      {Map<String, dynamic>? context, StackTrace? stackTrace, DateTime? timestamp}) {
    // Your custom formatting logic
    return '[${timestamp ?? DateTime.now()}] $message';
  }
}
```

## Error Handling

The logging system is designed to be robust and prevent logging failures from affecting your application:

- Handler errors are caught and logged to stderr
- Failed handlers don't prevent other handlers from working
- Configuration errors are handled gracefully with fallbacks

## Best Practices

### 1. Use Appropriate Log Levels

```dart
// Debug: Detailed information for development
logger.debug('Processing user ${user.id}');

// Info: General application flow
logger.info('User ${user.name} logged in');

// Warning: Potential issues that don't stop the application
logger.warning('Cache service is slow', context: {'responseTime': 5000});

// Error: Failures that need attention
logger.error('Database connection failed', context: {'error': e.toString()});

// Critical: System-wide failures
logger.critical('Application shutting down due to critical error');
```

### 2. Include Context

```dart
logger.info('Order processed', context: {
  'orderId': order.id,
  'userId': order.userId,
  'amount': order.amount,
  'items': order.items.length,
});
```

### 3. Use Channels for Organization

```dart
// Different channels for different concerns
logger.info('Payment processed', channel: 'payments');
logger.info('Email sent', channel: 'notifications');
logger.error('API rate limit exceeded', channel: 'api');
```

### 4. Handle Sensitive Data

```dart
// Avoid logging sensitive information
// Bad
logger.info('User login', context: {'password': user.password});

// Good
logger.info('User login', context: {'userId': user.id, 'ip': request.ip});
```

### 5. Configure for Production

```dart
// Production config
'logging': {
  'minimum_level': 'warning', // Reduce noise in production
  'handlers': {
    'file': {
      'enabled': true,
      'path': '/var/log/app/app.log',
      'rotate_daily': true,
    },
    'console': {
      'enabled': false, // Disable console in production
    },
  },
}
```

## Testing

The logging system includes comprehensive tests:

```bash
# Run all logging tests
dart test test/core/logging/

# Run specific test files
dart test test/core/logging/logger_test.dart
dart test test/core/logging/log_level_test.dart
```

## Performance Considerations

- Log level filtering happens early to avoid unnecessary processing
- Handlers are called asynchronously when possible
- File rotation is optimized to minimize I/O operations
- Consider using sampling for high-volume debug logging in production

## Migration from Other Logging Systems

If migrating from another logging system:

1. Update imports to use the new logging classes
2. Replace log level constants with `LogLevel` enum values
3. Update configuration format to match the new structure
4. Replace custom handlers with implementations of `LogHandler`

## Troubleshooting

### Common Issues

1. **Logs not appearing**: Check minimum log level configuration
2. **File permission errors**: Ensure the application has write access to log directories
3. **Performance issues**: Review log volume and consider increasing minimum log level
4. **Configuration not loading**: Verify config structure matches expected format

### Debug Logging

Enable debug logging to troubleshoot logging system issues:

```dart
final logger = Logger(minimumLevel: LogLevel.debug);
logger.debug('Logger initialized', context: {'config': config});
```</content>
<parameter name="filePath">d:\Users\Khedr\src\khadem\lib\src\core\logging\README.md

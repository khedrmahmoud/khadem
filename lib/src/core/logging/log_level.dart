/// Represents the severity levels for logging messages.
/// Each level has an associated integer value for comparison purposes.
enum LogLevel {
  /// Detailed information for debugging purposes.
  debug,

  /// General information about application operation.
  info,

  /// Warning messages that indicate potential issues.
  warning,

  /// Error messages that indicate failures in the application.
  error,

  /// Critical errors that require immediate attention.
  critical,
}

/// Extension methods for LogLevel to provide comparison functionality.
extension LogLevelExtension on LogLevel {
  /// Gets the integer value of the log level for comparison.
  int get value {
    switch (this) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
      case LogLevel.critical:
        return 4;
    }
  }

  /// Checks if this log level is at least as severe as the given level.
  /// Returns true if this level should be logged when the minimum level is [other].
  bool isAtLeast(LogLevel other) {
    return value >= other.value;
  }

  /// Creates a LogLevel from a string representation.
  /// Case-insensitive matching is supported.
  static LogLevel fromString(String level) {
    switch (level.toLowerCase()) {
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
        throw ArgumentError('Invalid log level: $level');
    }
  }

  /// Gets the string representation of the log level.
  String get name {
    return toString().split('.').last;
  }

  /// Gets the uppercase string representation of the log level.
  String get nameUpper {
    return name.toUpperCase();
  }
}
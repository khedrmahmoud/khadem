/// Represents different levels of logging.
enum LogLevel {
  /// Detailed information for debugging purposes
  debug,

  /// General information about system operation
  info,

  /// Warning messages for potentially harmful situations
  warning,

  /// Error messages for serious problems
  error,

  /// Critical messages for fatal errors that need immediate attention
  critical;

  /// Parses a string into a LogLevel
  static LogLevel fromString(String value) {
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


  /// Gets the string representation of the log level.
  String get name {
    return toString().split('.').last;
  }

  /// Gets the uppercase string representation of the log level.
  String get nameUpper {
    return name.toUpperCase();
  }
}

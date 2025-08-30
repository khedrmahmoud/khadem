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

  /// Returns true if this level is equal to or more severe than the given level
  bool isAtLeast(LogLevel level) => index >= level.index;
}

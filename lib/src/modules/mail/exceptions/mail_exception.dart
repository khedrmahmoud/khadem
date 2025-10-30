/// Exception thrown when mail operations fail.
class MailException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  MailException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() {
    if (originalError != null) {
      return 'MailException: $message (Caused by: $originalError)';
    }
    return 'MailException: $message';
  }
}

/// Exception thrown when mail configuration is invalid.
class MailConfigException extends MailException {
  MailConfigException(super.message, [super.originalError, super.stackTrace]);

  @override
  String toString() => 'MailConfigException: $message';
}

/// Exception thrown when mail transport fails.
class MailTransportException extends MailException {
  MailTransportException(super.message,
      [super.originalError, super.stackTrace,]);

  @override
  String toString() => 'MailTransportException: $message';
}

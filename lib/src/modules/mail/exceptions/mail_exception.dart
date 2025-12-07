import '../../../contracts/exceptions/app_exception.dart';

/// Exception thrown when mail operations fail.
class MailException extends AppException {
  MailException(
    super.message, {
    super.statusCode,
    super.title = 'Mail Error',
    super.type = 'mail_error',
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          details: {
            if (originalError != null) 'original_error': originalError.toString(),
            if (stackTrace != null) 'stack_trace': stackTrace.toString(),
          },
        );
}

/// Exception thrown when mail configuration is invalid.
class MailConfigException extends MailException {
  MailConfigException(
    super.message, {
    super.originalError,
    super.stackTrace,
  }) : super(
          title: 'Mail Configuration Error',
          type: 'mail_config_error',
        );
}

/// Exception thrown when mail transport fails.
class MailTransportException extends MailException {
  MailTransportException(
    super.message, {
    super.originalError,
    super.stackTrace,
  }) : super(
          title: 'Mail Transport Error',
          type: 'mail_transport_error',
        );
}

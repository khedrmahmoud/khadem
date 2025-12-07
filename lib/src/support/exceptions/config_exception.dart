import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when configuration operations fail.
class ConfigException extends AppException {
  ConfigException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 500,
          title: 'Configuration Error',
          type: 'config_error',
          details: details,
        );
}

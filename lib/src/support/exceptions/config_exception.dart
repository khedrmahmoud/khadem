import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when configuration operations fail.
class ConfigException extends AppException {
  ConfigException(super.message, {super.details})
    : super(
        statusCode: 500,
        title: 'Configuration Error',
        type: 'config_error',
      );
}

import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when configuration operations fail.
class ConfigException extends AppException {
  ConfigException(super.message) : super(statusCode: 500);
}

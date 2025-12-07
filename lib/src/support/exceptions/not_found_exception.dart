import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a requested resource is not found.
///
/// This exception is typically thrown when a database record, file,
/// or API endpoint does not exist.
class NotFoundException extends AppException {
  NotFoundException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 404,
          title: 'Not Found',
          type: 'not_found',
          details: details,
        );
}

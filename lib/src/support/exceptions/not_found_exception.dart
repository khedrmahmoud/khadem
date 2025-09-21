import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a requested resource is not found.
///
/// This exception is typically thrown when a database record, file,
/// or API endpoint does not exist.
class NotFoundException extends AppException {
  NotFoundException([super.message = 'Resource not found'])
      : super(statusCode: 404);
}

import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a requested resource is not found.
///
/// This exception is typically thrown when a database record, file,
/// or API endpoint does not exist.
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.details})
    : super(statusCode: 404, title: 'Not Found', type: 'not_found');
}

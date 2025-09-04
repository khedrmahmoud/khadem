import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a user attempts to access a forbidden resource.
///
/// This exception is typically thrown when a user is authenticated
/// but does not have the required permissions to access a resource.
class ForbiddenException extends AppException {
  ForbiddenException([super.message = 'Forbidden', dynamic details])
      : super(statusCode: 403, details: details);
}

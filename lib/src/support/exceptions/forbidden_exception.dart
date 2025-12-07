import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a user attempts to access a forbidden resource.
///
/// This exception is typically thrown when a user is authenticated
/// but does not have the required permissions to access a resource.
class ForbiddenException extends AppException {
  ForbiddenException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 403,
          title: 'Forbidden',
          type: 'forbidden',
          details: details,
        );
}

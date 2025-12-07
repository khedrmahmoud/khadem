import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a user is not authorized to access a resource.
///
/// This exception is typically thrown when authentication is required
/// but the user is not logged in or their session has expired.
class UnauthorizedException extends AppException {
  UnauthorizedException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 401,
          title: 'Unauthorized',
          type: 'unauthorized',
          details: details,
        );
}

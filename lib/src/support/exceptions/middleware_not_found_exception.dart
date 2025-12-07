import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a named middleware is not found.
class MiddlewareNotFoundException extends AppException {
  MiddlewareNotFoundException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 500,
          title: 'Middleware Not Found',
          type: 'middleware_not_found',
          details: details,
        );
}

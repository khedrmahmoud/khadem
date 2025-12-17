import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a named middleware is not found.
class MiddlewareNotFoundException extends AppException {
  MiddlewareNotFoundException(
    super.message, {
    super.details,
  }) : super(
          statusCode: 500,
          title: 'Middleware Not Found',
          type: 'middleware_not_found',
        );
}

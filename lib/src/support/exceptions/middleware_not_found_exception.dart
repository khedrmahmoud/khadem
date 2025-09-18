import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a named middleware is not found.
class MiddlewareNotFoundException extends AppException {
  MiddlewareNotFoundException(super.message,
      {super.statusCode = 404, super.details,});

  @override
  String toString() => message;
}

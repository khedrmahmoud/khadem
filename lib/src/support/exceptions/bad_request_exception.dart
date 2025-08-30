import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a request contains invalid data.
///
/// This exception is typically thrown when input validation fails
/// or when required parameters are missing.
class BadRequestException extends AppException {
  BadRequestException([String message = 'Bad request', dynamic details])
      : super(message, statusCode: 400, details: details);
}

import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a request contains invalid data.
///
/// This exception is typically thrown when input validation fails
/// or when required parameters are missing.
class BadRequestException extends AppException {
  BadRequestException(super.message, {super.details})
    : super(statusCode: 400, title: 'Bad Request', type: 'bad_request');
}

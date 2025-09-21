import '../../contracts/exceptions/app_exception.dart';

class MissingRequestContextException extends AppException {
  MissingRequestContextException(
      {String message =
          'Request is not available in the current context (zone).',
      super.statusCode = 500,
      super.details,})
      : super(message);
}

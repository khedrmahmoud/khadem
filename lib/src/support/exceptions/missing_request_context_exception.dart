import '../../contracts/exceptions/app_exception.dart';

class MissingRequestContextException extends AppException {
  MissingRequestContextException({
    String message = 'Request is not available in the current context (zone).',
    dynamic details,
  }) : super(
          message,
          statusCode: 500,
          title: 'Missing Request Context',
          type: 'missing_request_context',
          details: details,
        );
}

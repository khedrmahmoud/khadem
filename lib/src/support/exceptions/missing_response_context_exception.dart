import '../../contracts/exceptions/app_exception.dart';

class MissingResponseContextException extends AppException {
  MissingResponseContextException({
    String message = 'Response is not available in the current context (zone).',
    dynamic details,
  }) : super(
          message,
          statusCode: 500,
          title: 'Missing Response Context',
          type: 'missing_response_context',
          details: details,
        );
}

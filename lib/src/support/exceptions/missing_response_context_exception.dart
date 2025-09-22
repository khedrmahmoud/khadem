import '../../contracts/exceptions/app_exception.dart';

class MissingResponseContextException extends AppException {
  MissingResponseContextException({
    String message = 'Response is not available in the current context (zone).',
    super.statusCode = 500,
    super.details,
  }) : super(message);
}

import '../../contracts/exceptions/app_exception.dart';

class MissingServerContextException extends AppException {
  MissingServerContextException({
    String message = 'Server context is not available in the current zone.',
    super.statusCode = 500,
    super.details,
  }) : super(message);
}

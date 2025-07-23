import '../../../contracts/exceptions/app_exception.dart';

class AuthException extends AppException {
  AuthException(
    super.message, {
    super.statusCode = 401,
    String? stackTrace,
  }) : super(details: stackTrace);
}

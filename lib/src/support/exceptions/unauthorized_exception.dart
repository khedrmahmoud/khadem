import '../../contracts/exceptions/app_exception.dart';

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Unauthorized'])
      : super(statusCode: 401);
}

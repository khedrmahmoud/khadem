import '../../contracts/exceptions/app_exception.dart';

class NotFoundException extends AppException {
  NotFoundException(super.message) : super(statusCode: 404);
}

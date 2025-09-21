import '../../contracts/exceptions/app_exception.dart';

class CacheException extends AppException {
  CacheException(super.message, {super.statusCode = 500, super.details});
}

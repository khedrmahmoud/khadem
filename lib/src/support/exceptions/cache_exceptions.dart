import '../../contracts/exceptions/app_exception.dart';

class CacheException extends AppException {
  CacheException(super.message, {super.statusCode, super.details})
    : super(title: 'Cache Error', type: 'cache_error');
}

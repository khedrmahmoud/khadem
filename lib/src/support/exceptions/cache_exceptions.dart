import '../../contracts/exceptions/app_exception.dart';

class CacheException extends AppException {
  CacheException(
    String message, {
    int statusCode = 500,
    dynamic details,
  }) : super(
          message,
          statusCode: statusCode,
          title: 'Cache Error',
          type: 'cache_error',
          details: details,
        );
}

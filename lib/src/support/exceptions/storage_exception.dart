import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when storage operations fail
class StorageException extends AppException {
  StorageException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 500,
          title: 'Storage Error',
          type: 'storage_error',
          details: details,
        );
}

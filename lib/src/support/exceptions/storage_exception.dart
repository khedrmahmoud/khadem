import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when storage operations fail
class StorageException extends AppException {
  StorageException([
    super.message = 'Storage operation failed',
    dynamic details,
  ]) : super(statusCode: 500, details: details);
}

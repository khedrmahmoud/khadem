import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when storage operations fail
class StorageException extends AppException {
  StorageException(super.message, {super.details})
    : super(statusCode: 500, title: 'Storage Error', type: 'storage_error');
}

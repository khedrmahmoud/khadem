import '../../contracts/exceptions/app_exception.dart';

/// Exception class for database errors
class DatabaseException extends AppException {
  DatabaseException(super.message) : super(statusCode: 500);
}

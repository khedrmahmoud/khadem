import '../../contracts/exceptions/app_exception.dart';

/// Exception class for database errors
class DatabaseException extends AppException {
  DatabaseException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 500,
          title: 'Database Error',
          type: 'database_error',
          details: details,
        );
}

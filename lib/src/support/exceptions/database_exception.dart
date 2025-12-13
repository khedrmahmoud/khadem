import '../../contracts/exceptions/app_exception.dart';

/// Exception class for database errors
class DatabaseException extends AppException {
  final String? sql;
  final List<dynamic>? bindings;

  DatabaseException(
    String message, {
    dynamic details,
    this.sql,
    this.bindings,
  }) : super(
          message,
          statusCode: 500,
          title: 'Database Error',
          type: 'database_error',
          details: {
            if (details != null) 'error': details,
            if (sql != null) 'sql': sql,
            if (bindings != null) 'bindings': bindings,
          },
        );
}

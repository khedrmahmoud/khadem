import '../http/context/response_context.dart';
import '../http/response/response.dart';
import '../../contracts/exceptions/app_exception.dart';
import 'exception_reporter.dart';

/// Handles exceptions raised in the application and sends a JSON
/// response with details about the error.
///
/// If the exception is an instance of [AppException], it will be reported
/// to the [ExceptionReporter] and the original status code will be used.
///
/// Otherwise, the exception will be reported with a 500 status code
/// and a generic "Internal Server Error" message.
class ExceptionHandler {
  static void handle(Response? res, Object error, [StackTrace? stackTrace]) {
    final response = res ?? ResponseContext.response;
    if (error is AppException) {
      ExceptionReporter.reportAppException(error, stackTrace);

      response.status(error.statusCode).sendJson(error.toResponse());
    } else {
      ExceptionReporter.reportException(error, stackTrace);
      response.status(500).sendJson({
        'message': 'Internal Server Error',
        'error': error.toString(),
      });
    }
  }
}

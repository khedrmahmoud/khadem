import '../../contracts/exceptions/app_exception.dart';

class QueueException extends AppException {
  QueueException(
    String message, {
    int statusCode = 500,
    dynamic details,
  }) : super(
          message,
          statusCode: statusCode,
          title: 'Queue Error',
          type: 'queue_error',
          details: details,
        );
}

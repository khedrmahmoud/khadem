import '../../contracts/exceptions/app_exception.dart';

class QueueException extends AppException {
  QueueException(
    super.message, {
    super.statusCode,
    super.details,
  }) : super(
          title: 'Queue Error',
          type: 'queue_error',
        );
}

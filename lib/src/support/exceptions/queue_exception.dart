import '../../contracts/exceptions/app_exception.dart';

class QueueException extends AppException {
  QueueException(super.message,
      {super.statusCode = 500, super.details = const {},});
}

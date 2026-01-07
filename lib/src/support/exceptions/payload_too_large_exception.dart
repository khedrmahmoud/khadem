import 'package:khadem/src/contracts/exceptions/app_exception.dart';

class PayloadTooLargeException extends AppException {
  PayloadTooLargeException(super.message)
      : super(statusCode: 413, title: 'Payload Too Large');
}

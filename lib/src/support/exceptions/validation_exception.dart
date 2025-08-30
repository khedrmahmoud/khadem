import '../../contracts/exceptions/app_exception.dart';
import '../../core/lang/lang.dart';

class ValidationException extends AppException {
  ValidationException(Map<String, String> errors)
      : super(Lang.t('validation_failed_validation'),
            statusCode: 422, details: errors,);
}

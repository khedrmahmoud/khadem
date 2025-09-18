import '../../contracts/exceptions/app_exception.dart';
import '../../core/lang/lang.dart';

class ValidationException extends AppException {
  final Map<String, String> errors;

  ValidationException(this.errors, {dynamic additionalDetails})
      : super(Lang.t('validation_failed_validation'),
            statusCode: 422,
            details: additionalDetails ?? errors,);
}

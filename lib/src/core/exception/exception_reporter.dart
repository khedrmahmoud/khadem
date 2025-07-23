import '../../contracts/exceptions/app_exception.dart';
import '../../application/khadem.dart';

/// Central place to log or report exceptions to a third-party service.
///
/// This class is used to abstract the actual reporting process of exceptions.
/// The default implementation will log the error to the logger. However, you can
/// easily swap it out with a third-party service like Sentry or Rollbar.
class ExceptionReporter {
  static void reportAppException(AppException error, [StackTrace? stackTrace]) {
    Khadem.logger.error(error.message, stackTrace: stackTrace);
  }

  static void reportException(Object error, [StackTrace? stackTrace]) {
    Khadem.logger.error(error.toString(), stackTrace: stackTrace);
  }
}

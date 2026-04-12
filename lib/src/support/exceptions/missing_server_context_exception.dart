import '../../contracts/exceptions/app_exception.dart';

class MissingServerContextException extends AppException {
  MissingServerContextException({
    String message = 'Server context is not available in the current zone.',
    dynamic details,
  }) : super(
         message,
         statusCode: 500,
         title: 'Missing Server Context',
         type: 'missing_server_context',
         details: details,
       );
}

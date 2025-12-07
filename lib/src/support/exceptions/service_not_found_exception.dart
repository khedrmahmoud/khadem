import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a service is not found in the container.
class ServiceNotFoundException extends AppException {
  ServiceNotFoundException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 500,
          title: 'Service Not Found',
          type: 'service_not_found',
          details: details,
        );
}

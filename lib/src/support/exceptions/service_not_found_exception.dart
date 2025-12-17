import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a service is not found in the container.
class ServiceNotFoundException extends AppException {
  ServiceNotFoundException(
    super.message, {
    super.details,
  }) : super(
          statusCode: 500,
          title: 'Service Not Found',
          type: 'service_not_found',
        );
}

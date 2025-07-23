import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a service is not found in the container.
class ServiceNotFoundException extends AppException {
  ServiceNotFoundException(super.message) : super(statusCode: 500);
}

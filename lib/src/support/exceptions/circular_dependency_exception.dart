import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a circular dependency is detected in the container.
class CircularDependencyException extends AppException {
  CircularDependencyException(super.message) : super(statusCode: 500);
}

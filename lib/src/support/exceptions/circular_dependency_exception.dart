import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a circular dependency is detected in the container.
class CircularDependencyException extends AppException {
  CircularDependencyException(
    String message, {
    dynamic details,
  }) : super(
          message,
          statusCode: 500,
          title: 'Circular Dependency Error',
          type: 'circular_dependency_error',
          details: details,
        );
}

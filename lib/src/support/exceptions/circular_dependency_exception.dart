import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a circular dependency is detected in the container.
class CircularDependencyException extends AppException {
  CircularDependencyException(
    super.message, {
    super.details,
  }) : super(
          statusCode: 500,
          title: 'Circular Dependency Error',
          type: 'circular_dependency_error',
        );
}

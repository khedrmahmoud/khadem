import '../../application/khadem.dart';
import '../../contracts/container/container_interface.dart';

/// Resolves a service from the container.
///
/// If [T] is provided, it resolves the service of type [T].
/// If no type is provided (dynamic), it returns the [ContainerInterface].
///
/// Example:
/// ```dart
/// final logger = app<Logger>();
/// final container = app();
/// ```
T app<T>([String? context]) {
  // If T is dynamic (no type argument provided), return the container
  if (T == dynamic || T == Object) {
    return Khadem.container as T;
  }
  
  // Otherwise resolve the service
  return Khadem.make<T>(context);
}

/// Alias for [app] to resolve a service.
///
/// Example:
/// ```dart
/// final logger = resolve<Logger>();
/// ```
T resolve<T>([String? context]) => Khadem.make<T>(context);

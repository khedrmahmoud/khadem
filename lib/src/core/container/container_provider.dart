import '../../contracts/container/container_interface.dart';
import 'service_container.dart';

/// Provides a globally accessible dependency injection container instance.
///
/// This provider serves as a central access point for the application's
/// dependency injection container, allowing services to be resolved
/// without manually passing the container instance throughout the codebase.
/// It follows the singleton pattern to ensure a single container instance
/// is used throughout the application lifecycle.
///
/// Example usage:
/// ```dart
/// // Register a service
/// ContainerProvider.instance.bind<Logger>((container) => ConsoleLogger());
///
/// // Resolve a service
/// final logger = ContainerProvider.instance.resolve<Logger>();
/// ```
class ContainerProvider {
  /// The global container instance.
  ///
  /// This is a singleton instance of [ServiceContainer] that is shared
  /// across the entire application. All dependency resolutions should
  /// go through this instance.
  static final ContainerInterface _instance = ServiceContainer();

  /// Gets the global container instance.
  ///
  /// Returns the singleton container instance that can be used to
  /// register and resolve dependencies throughout the application.
  ///
  /// Returns the global [ContainerInterface] instance
  static ContainerInterface get instance => _instance;
}

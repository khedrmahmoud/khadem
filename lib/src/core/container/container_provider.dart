import '../../contracts/container/container_interface.dart';
import 'service_container.dart';

/// Provides a globally accessible DI container instance.
///
/// Used as a central access point for resolving dependencies
/// without manually passing the container.
class ContainerProvider {
  static final ContainerInterface _instance = ServiceContainer();

  /// Global container instance.
  static ContainerInterface get instance => _instance;
}

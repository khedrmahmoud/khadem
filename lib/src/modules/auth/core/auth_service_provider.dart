import '../../../contracts/container/container_interface.dart';
import '../../../contracts/provider/service_provider.dart';
import '../services/auth_manager.dart';

/// Service provider for authentication services
///
/// This provider registers the AuthManager service in the dependency injection
/// container, making authentication functionality available throughout the application.
///
/// The provider follows the standard service provider pattern:
/// - Register: Bind services to the container
/// - Boot: Perform any initialization after all services are registered
///
/// Example usage:
/// ```dart
/// // In application bootstrap
/// final container = Container();
/// final authProvider = AuthServiceProvider();
/// await authProvider.register(container);
/// await authProvider.boot(container);
///
/// // Later in the application
/// final authManager = container.make<AuthManager>();
/// ```
class AuthServiceProvider extends ServiceProvider {
  /// Registers authentication services in the container
  ///
  /// This method binds the AuthManager singleton to the container,
  /// making it available for dependency injection throughout the application.
  ///
  /// [container] The dependency injection container
  @override
  Future<void> register(ContainerInterface container) async {
    container.bind<AuthManager>((_) => AuthManager());
  }

  /// Boots the authentication services
  ///
  /// This method is called after all service providers have been registered.
  /// It can be used for any post-registration initialization.
  ///
  /// [container] The dependency injection container
  @override
  Future<void> boot(ContainerInterface container) async {
    // No additional boot logic required for auth services
  }
}

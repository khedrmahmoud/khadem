import '../../../contracts/container/container_interface.dart';
import '../../../contracts/provider/service_provider.dart';
import '../../../support/services/secure_token_generator.dart';
import '../config/khadem_auth_config.dart';
import '../contracts/auth_config.dart';
import '../contracts/auth_repository.dart';
import '../contracts/password_verifier.dart';
import '../contracts/token_generator.dart';
import '../repositories/database_auth_repository.dart';
import '../services/auth_manager.dart';
import '../services/hash_password_verifier.dart';
import '../services/jwt_auth_service.dart';
import '../services/token_auth_service.dart';

/// Enhanced Authentication Service Provider
///
/// This service provider registers all authentication-related services
/// and dependencies in the container. It follows the Dependency Injection
/// pattern and ensures proper service registration and configuration.
///
/// Services registered:
/// - AuthConfig: Configuration access
/// - AuthRepository: Data access layer
/// - PasswordVerifier: Password hashing and verification
/// - TokenGenerator: Secure token generation
/// - EnhancedAuthManager: Main authentication facade
/// - Individual auth drivers (JWT, Token)
///
/// Example usage:
/// ```dart
/// // In application bootstrap
/// final container = Container();
/// final authProvider = EnhancedAuthServiceProvider();
/// await authProvider.register(container);
/// await authProvider.boot(container);
///
/// // Later in the application
/// final authManager = container.make<EnhancedAuthManager>();
/// final jwtService = authManager.driver('jwt');
/// ```
class AuthServiceProvider extends ServiceProvider {
  /// Registers authentication services in the container
  ///
  /// This method binds all authentication services to the container,
  /// including core contracts and their implementations.
  ///
  /// [container] The dependency injection container
  @override
  Future<void> register(ContainerInterface container) async {
    // Register core contracts
    await _registerCoreContracts(container);
    
    // Register authentication drivers
    await _registerAuthDrivers(container);
    
    // Register the main auth manager
    await _registerAuthManager(container);
  }

  /// Boots the authentication services
  ///
  /// This method performs any post-registration initialization,
  /// such as setting up driver factories and cleanup schedules.
  ///
  /// [container] The dependency injection container
  @override
  Future<void> boot(ContainerInterface container) async {
    // Perform any post-registration initialization
    await _bootAuthServices(container);
  }

  /// Registers core authentication contracts
  Future<void> _registerCoreContracts(ContainerInterface container) async {
    // Register AuthConfig as singleton
    container.singleton<AuthConfig>((_) => KhademAuthConfig());

    // Register AuthRepository as singleton
    container.singleton<AuthRepository>((_) => DatabaseAuthRepository());

    // Register PasswordVerifier as singleton
    container.singleton<PasswordVerifier>((_) => HashPasswordVerifier());

    // Register TokenGenerator as singleton
    container.singleton<TokenGenerator>((_) => SecureTokenGenerator());
  }

  /// Registers authentication drivers
  Future<void> _registerAuthDrivers(ContainerInterface container) async {
    // Register JWT Auth Service factory
    container.bind<EnhancedJWTAuthService>(
      (c) => EnhancedJWTAuthService(
        providerKey: 'users', // Default provider
        repository: c.resolve<AuthRepository>(),
        config: c.resolve<AuthConfig>(),
        passwordVerifier: c.resolve<PasswordVerifier>(),
        tokenGenerator: c.resolve<TokenGenerator>(),
      ),
    );

    // Register Token Auth Service factory
    container.bind<EnhancedTokenAuthService>(
      (c) => EnhancedTokenAuthService(
        providerKey: 'users', // Default provider
        repository: c.resolve<AuthRepository>(),
        config: c.resolve<AuthConfig>(),
        passwordVerifier: c.resolve<PasswordVerifier>(),
        tokenGenerator: c.resolve<TokenGenerator>(),
      ),
    );
  }

  /// Registers the main authentication manager
  Future<void> _registerAuthManager(ContainerInterface container) async {
    container.singleton<AuthManager>(
      (c) => AuthManager(
        authConfig: c.resolve<AuthConfig>(),
      ),
    );

    // Note: Container doesn't support aliases, use direct resolution
    // For backward compatibility, users should resolve EnhancedAuthManager directly
  }

  /// Performs post-registration boot operations
  Future<void> _bootAuthServices(ContainerInterface container) async {
    // Register custom driver factories with the auth manager
    _registerCustomDriverFactories();
    
    // Set up any cleanup schedules
    await _setupCleanupSchedules(container);
  }

  /// Registers custom authentication driver factories
  void _registerCustomDriverFactories() {
    // Example: Register a custom OAuth driver factory
    AuthManager.registerDriverFactory(
      'oauth',
      (providerKey) => throw UnsupportedError(
        'OAuth driver not implemented. Please implement and register an OAuth driver.',
      ),
    );

    // Example: Register a custom LDAP driver factory
    AuthManager.registerDriverFactory(
      'ldap',
      (providerKey) => throw UnsupportedError(
        'LDAP driver not implemented. Please implement and register an LDAP driver.',
      ),
    );
  }

  /// Sets up cleanup schedules for expired tokens
  Future<void> _setupCleanupSchedules(ContainerInterface container) async {
    // This would typically set up periodic cleanup of expired tokens
    // For now, this is a placeholder for future implementation
    
    // Example implementation:
    // final authManager = container.make<EnhancedAuthManager>();
    // Timer.periodic(Duration(hours: 1), (timer) {
    //   authManager.driver.cleanupExpiredTokens();
    // });
  }
}

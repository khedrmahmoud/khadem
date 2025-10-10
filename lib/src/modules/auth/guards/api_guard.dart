import '../config/khadem_auth_config.dart';
import '../contracts/auth_config.dart';
import '../drivers/auth_driver.dart';
import '../drivers/jwt_driver.dart';
import '../drivers/token_driver.dart';
import '../exceptions/auth_exception.dart';
import '../repositories/database_auth_repository.dart';
import '../services/hash_password_verifier.dart';
import 'base_guard.dart';

/// API authentication guard
///
/// This guard handles authentication for API requests. It uses
/// token-based authentication and is suitable for stateless API
/// authentication where tokens are sent in headers.
class ApiGuard extends Guard {
  /// Creates an API guard
  ApiGuard({
    required super.config,
    required super.driver, required super.providerKey, super.repository,
    super.passwordVerifier,
  });

  /// Factory constructor for easy instantiation
  factory ApiGuard.create(String providerKey, AuthDriver driver) {
    return ApiGuard(
      config: KhademAuthConfig(),
      repository: DatabaseAuthRepository(),
      passwordVerifier: HashPasswordVerifier(),
      driver: driver,
      providerKey: providerKey,
    );
  }

  /// Factory constructor with config
  factory ApiGuard.fromConfig(AuthConfig config, String guardName, [String? providerKey]) {
    final guardConfig = config.getGuard(guardName);
    final driverName = guardConfig['driver'] as String;

    // Use provided provider key, or get default provider
    final effectiveProviderKey = providerKey ?? _getDefaultProviderKey(config);

    final driver = _createDriver(driverName, config, effectiveProviderKey);

    return ApiGuard(
      config: config,
      driver: driver,
      providerKey: effectiveProviderKey,
    );
  }

  /// Gets the default provider key
  static String _getDefaultProviderKey(AuthConfig config) {
    final providerKeys = config.getAllProviderKeys();
    if (providerKeys.isEmpty) {
      throw AuthException('No providers configured');
    }

    // Return the first provider key as default
    return providerKeys.first;
  }

  /// Creates the appropriate driver
  static AuthDriver _createDriver(
    String driverName,
    AuthConfig config,
    String providerKey,
  ) {
    switch (driverName.toLowerCase()) {
      case 'jwt':
        return JWTDriver.fromConfig(config, providerKey);
      case 'token':
        return TokenDriver.fromConfig(config, providerKey);
      default:
        throw AuthException('Unsupported driver: $driverName');
    }
  }
}
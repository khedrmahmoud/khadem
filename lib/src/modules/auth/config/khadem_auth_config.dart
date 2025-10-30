import 'package:khadem/src/support/exceptions/not_found_exception.dart';

import '../../../application/khadem.dart';
import '../contracts/auth_config.dart';
import '../exceptions/auth_exception.dart';

/// Khadem implementation of AuthConfig
///
/// This class implements the AuthConfig interface using the Khadem
/// configuration system. It provides access to authentication
/// configuration with proper error handling.
class KhademAuthConfig implements AuthConfig {
  /// Cache for configuration data to avoid repeated lookups
  Map<String, dynamic>? _authConfig;

  /// Gets the full auth configuration with caching
  Map<String, dynamic> _getAuthConfig() {
    _authConfig ??= Khadem.config.section('auth') ?? {};

    if (_authConfig!.isEmpty) {
      throw AuthException(
        'Authentication configuration not found. Please check your config/auth file.',
      );
    }

    return _authConfig!;
  }

  @override
  Map<String, dynamic> getProvider(String providerKey) {
    final config = _getAuthConfig();
    final providers = config['providers'] as Map<String, dynamic>?;

    if (providers == null || !providers.containsKey(providerKey)) {
      throw AuthException(
        'Authentication provider "$providerKey" not found in configuration.',
      );
    }

    return providers[providerKey] as Map<String, dynamic>;
  }

  @override
  List<Map<String, dynamic>> getProvidersForGuard(String guardName) {
    final config = _getAuthConfig();
    final providers = config['providers'] as Map<String, dynamic>?;

    if (providers == null) {
      return [];
    }

    // With the new structure, all providers can work with any guard
    // The guard determines the driver, provider provides model/table info
    return providers.values
        .map((provider) => provider as Map<String, dynamic>)
        .toList();
  }

  @override
  Map<String, dynamic> getGuard(String guardName) {
    final config = _getAuthConfig();
    final guards = config['guards'] as Map<String, dynamic>?;

    if (guards == null || !guards.containsKey(guardName)) {
      throw AuthException(
        'Authentication guard "$guardName" not found in configuration.',
      );
    }

    return guards[guardName] as Map<String, dynamic>;
  }

  @override
  String getDefaultGuard() {
    final config = _getAuthConfig();
    final defaults = config['defaults'] as Map<String, dynamic>?;
    final defaultGuard =
        defaults?['guard'] as String? ?? config['default'] as String?;

    if (defaultGuard == null) {
      throw NotFoundException(
        'No default guard specified in authentication configuration.',
      );
    }

    return defaultGuard;
  }

  @override
  T getOrDefault<T>(String key, T defaultValue) {
    final config = _getAuthConfig();
    return config[key] as T? ?? defaultValue;
  }

  @override
  bool hasProvider(String providerKey) {
    try {
      getProvider(providerKey);
      return true;
    } on AuthException {
      return false;
    }
  }

  @override
  bool hasGuard(String guardName) {
    try {
      getGuard(guardName);
      return true;
    } on AuthException {
      return false;
    }
  }

  @override
  List<String> getAllProviderKeys() {
    final config = _getAuthConfig();
    final providers = config['providers'] as Map<String, dynamic>?;

    if (providers == null) {
      return [];
    }

    return providers.keys.toList();
  }

  @override
  String getDefaultProvider() {
    final config = _getAuthConfig();
    final defaults = config['defaults'] as Map<String, dynamic>?;
    final defaultProvider =
        defaults?['provider'] as String? ?? config['default'] as String?;

    if (defaultProvider == null) {
      throw NotFoundException(
        'No default provider specified in authentication configuration.',
      );
    }

    return defaultProvider;
  }
}

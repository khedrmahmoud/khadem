/// Configuration interface for authentication services
///
/// This interface defines the contract for accessing authentication
/// configuration data. It allows for different configuration sources
/// and provides a consistent interface for auth services.
abstract class AuthConfig {
  /// Gets the authentication provider configuration
  ///
  /// [providerKey] The provider key to retrieve
  /// Returns the provider configuration
  /// Throws [AuthException] if provider is not found
  Map<String, dynamic> getProvider(String providerKey);

  /// Gets providers for a specific guard
  ///
  /// [guardName] The guard name to get providers for
  /// Returns a list of provider configurations for the guard
  List<Map<String, dynamic>> getProvidersForGuard(String guardName);

  /// Gets all available provider keys
  ///
  /// Returns a list of all provider keys
  List<String> getAllProviderKeys();

  /// Gets the guard configuration
  ///
  /// [guardName] The guard name to retrieve
  /// Returns the guard configuration
  /// Throws [AuthException] if guard is not found
  Map<String, dynamic> getGuard(String guardName);

  /// Gets the default guard name
  ///
  /// Returns the default guard name
  String getDefaultGuard();

  /// Gets the default provider key
  ///
  /// Returns the default provider key
  String getDefaultProvider();

  /// Gets a configuration value with a default fallback
  ///
  /// [key] The configuration key
  /// [defaultValue] The default value if key is not found
  /// Returns the configuration value or default
  T getOrDefault<T>(String key, T defaultValue);

  /// Checks if a provider exists
  ///
  /// [providerKey] The provider key to check
  /// Returns true if provider exists
  bool hasProvider(String providerKey);

  /// Checks if a guard exists
  ///
  /// [guardName] The guard name to check
  /// Returns true if guard exists
  bool hasGuard(String guardName);
}

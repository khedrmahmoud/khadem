/// Configuration contract that defines the required methods for config management
abstract class ConfigContract {
  /// Get a configuration value
  T? get<T>(String key, [T? defaultValue]);

  /// Set a configuration value
  void set<T>(String key, T value);

  /// Check if a configuration key exists
  bool has(String key);

  /// Get all configuration values
  Map<String, dynamic> all();

  /// Load configuration from a file
  Future<void> load(String path);

  /// Save configuration to a file
  Future<void> save(String path);
}

/// Defines the contract for a configuration management system.
///
/// This interface allows you to interact with application configuration
/// settings, including retrieving, setting, checking existence, and
/// managing entire configuration sections.
///
/// Ideal for use cases like loading `.env`, JSON, YAML, or any custom config sources.
abstract interface class ConfigInterface {
  /// Retrieves the value associated with the given [key].
  ///
  /// If the key does not exist, it returns the optional [defaultValue].
  ///
  /// Example:
  /// ```dart
  /// final port = config.get<int>('server.port', 3000);
  /// ```
  ///
  /// Returns `null` if the key is missing and no [defaultValue] is provided.
  T? get<T>(String key, [T? defaultValue]);

  /// Sets a configuration [value] for the specified [key].
  ///
  /// This can be used to override existing values or define new ones at runtime.
  ///
  /// Example:
  /// ```dart
  /// config.set('app.debug', true);
  /// ```
  void set(String key, dynamic value);

  /// Checks if a given [key] exists in the configuration.
  ///
  /// Returns `true` if the key exists, otherwise `false`.
  ///
  /// Example:
  /// ```dart
  /// if (config.has('database.host')) {
  ///   // Use the value
  /// }
  /// ```
  bool has(String key);

  /// Returns all loaded configuration values as a flat `Map<String, dynamic>`.
  ///
  /// Useful for debugging, exporting, or inspecting the entire config at once.
  Map<String, dynamic> all();

  /// Retrieves an entire named configuration [section] as a nested map.
  ///
  /// For example, if your config has a `database` section:
  /// ```json
  /// {
  ///   "database": {
  ///     "host": "localhost",
  ///     "port": 3306
  ///   }
  /// }
  /// ```
  /// You can retrieve it via:
  /// ```dart
  /// final dbConfig = config.section('database');
  /// ```
  ///
  /// Returns `null` if the section does not exist.
  Map<String, dynamic>? section(String name);

  /// Reloads the configuration from its source.
  ///
  /// This is useful if you support hot-reloading config at runtime,
  /// such as re-reading `.env` files or external services.
  void reload();

  /// Loads configuration data from a registry map.
  ///
  /// The [registry] should be a map of section names to their key-value pairs.
  ///
  /// Example:
  /// ```dart
  /// config.loadFromRegistry({
  ///   'app': {'name': 'Khadem', 'env': 'production'},
  ///   'database': {'host': 'localhost'}
  /// });
  /// ```
  void loadFromRegistry(Map<String, Map<String, dynamic>> registry);
}

/// Contract for accessing and managing environment variables.
///
/// This interface abstracts access to `.env` files or environment
/// variables loaded into memory, providing helpers for typed access.
///
/// Example usage:
/// ```dart
/// final port = env.getInt('PORT', defaultValue: 3000);
/// final debug = env.getBool('APP_DEBUG', defaultValue: false);
/// ```
abstract interface class EnvInterface {
  /// Returns the raw string value for the given [key], or `null` if not found.
  ///
  /// Example:
  /// ```dart
  /// final host = env.get('DATABASE_HOST');
  /// ```
  String? get(String key);

  /// Returns the value of the [key] if found, otherwise returns [defaultValue].
  ///
  /// This avoids needing to manually check for null.
  String getOrDefault(String key, String defaultValue);

  /// Returns the value of the [key] as a boolean.
  ///
  /// Accepts `"true"`, `"1"` (case-insensitive) as `true`.
  ///
  /// If the value is missing or invalid, returns the [defaultValue].
  bool getBool(String key, {bool defaultValue = false});

  /// Returns the value of the [key] as an integer.
  ///
  /// If parsing fails or key doesn't exist, returns the [defaultValue].
  int getInt(String key, {int defaultValue = 0});

  /// Returns the value of the [key] as a double.
  ///
  /// If parsing fails or key doesn't exist, returns the [defaultValue].
  double getDouble(String key, {double defaultValue = 0.0});

  /// Returns a list of strings split by [separator].
  ///
  /// The default separator is a comma (`,`).
  ///
  /// Example:
  /// ```env
  /// ALLOWED_ORIGINS=http://localhost:3000,https://myapp.com
  /// ```
  /// ```dart
  /// final origins = env.getList('ALLOWED_ORIGINS');
  /// ```
  List<String> getList(String key,
      {String separator = ',', List<String> defaultValue = const []});

  /// Sets a runtime environment variable [key] to the given [value].
  ///
  /// This does not persist to disk; it's in-memory only.
  void set(String key, String value);

  /// Checks if a [key] exists in the current environment.
  ///
  /// Returns `true` if the key exists, `false` otherwise.
  bool has(String key);

  /// Returns a map of all loaded environment variables.
  ///
  /// Useful for debugging or exporting.
  Map<String, String> all();

  /// A list of `.env` files that have been loaded.
  ///
  /// This can be used to trace config sources.
  List<String> get loadedFiles;

  /// Loads variables from a `.env` file located at [path].
  ///
  /// Typically used at app startup.
  void loadFromFile(String path);

  /// Clears all currently loaded environment variables from memory.
  ///
  /// Useful for testing or reloading environment.
  void clear();

  /// Ensures that all [requiredKeys] exist in the environment.
  ///
  /// Returns a list of missing keys (empty list means all are valid).
  ///
  /// Example:
  /// ```dart
  /// final missing = env.validateRequired(['APP_KEY', 'DB_HOST']);
  /// if (missing.isNotEmpty) {
  ///   throw Exception('Missing environment keys: ${missing.join(', ')}');
  /// }
  /// ```
  List<String> validateRequired(List<String> requiredKeys);
}

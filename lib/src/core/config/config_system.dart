import 'dart:convert';
import 'dart:io';

import '../../contracts/config/config_contract.dart';
import '../../support/exceptions/config_exception.dart';

/// The default configuration system used in Khadem.
///
/// The ConfigSystem provides a hierarchical configuration management system
/// that supports loading from JSON files, environment-specific overrides,
/// dot notation access, and automatic cache management. It's designed to be
/// flexible and performant for various application configurations.
///
/// ## Features
///
/// - **Hierarchical Loading**: Base configs + environment-specific overrides
/// - **Dot Notation Access**: Access nested values with `app.database.host`
/// - **Multiple Formats**: JSON support (YAML planned)
/// - **Caching**: In-memory caching with TTL-based expiration
/// - **Runtime Overrides**: Dynamic configuration updates
/// - **Type Safety**: Generic type support for value retrieval
///
/// ## Directory Structure
///
/// ```
/// config/
/// ├── app.json              # Base application config
/// ├── database.json         # Base database config
/// └── development/          # Environment-specific overrides
///     ├── app.json         # Development app overrides
///     └── database.json    # Development database overrides
/// ```
///
/// ## Usage
///
/// ```dart
/// // Create configuration system
/// final config = ConfigSystem(
///   configPath: 'config',
///   environment: 'development',
///   useCache: true,
///   cacheTtl: Duration(minutes: 5),
/// );
///
/// // Access values with dot notation
/// final appName = config.get<String>('app.name');
/// final dbHost = config.get<String>('database.host', 'localhost');
/// final debug = config.get<bool>('app.debug', false);
/// final port = config.get<int>('app.port', 3000);
///
/// // Set runtime values
/// config.set('app.runtime_key', 'runtime_value');
///
/// // Check if key exists
/// if (config.has('database.url')) {
///   // Database is configured
/// }
///
/// // Get entire sections
/// final appConfig = config.section('app');
/// final allConfig = config.all();
/// ```
class ConfigSystem implements ConfigInterface {
  /// Internal storage for configuration data.
  final Map<String, dynamic> _config = {};

  /// Path to the configuration directory (e.g., 'config').
  final String _configPath;

  /// Current environment name (e.g., 'development', 'production').
  final StringBuffer _environment;

  /// Whether to cache configs in memory and auto-reload on TTL expiration.
  final bool _useCache;

  /// Time-to-live for each cached config file.
  final Duration _cacheTtl;

  /// Last loaded timestamps for each config file.
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Creates a new configuration system.
  ///
  /// [configPath] should point to a directory containing configuration files.
  /// [environment] specifies the environment name for loading environment-specific configs.
  /// [useCache] enables in-memory caching with automatic reloading.
  /// [cacheTtl] sets the time-to-live for cached configurations.
  ///
  /// ```dart
  /// final config = ConfigSystem(
  ///   configPath: 'config',
  ///   environment: 'production',
  ///   useCache: true,
  ///   cacheTtl: Duration(minutes: 10),
  /// );
  /// ```
  ///
  /// Throws [ConfigException] if the configuration directory doesn't exist.
  ConfigSystem({
    required String configPath,
    required String environment,
    bool useCache = true,
    Duration cacheTtl = const Duration(minutes: 5),
  })  : _configPath = configPath,
        _environment = StringBuffer(environment),
        _useCache = useCache,
        _cacheTtl = cacheTtl {
    _loadConfigurations();
  }

  /// Changes the current environment and reloads configurations.
  ///
  /// This will reload all configuration files and merge environment-specific
  /// overrides for the new environment.
  ///
  /// ```dart
  /// config.setEnvironment('production');
  /// ```
  void setEnvironment(String environment) {
    _environment.clear();
    _environment.write(environment);
    _loadConfigurations();
  }

  /// Loads all configuration files from the base and environment directories.
  ///
  /// This method is called automatically during initialization and when
  /// the environment is changed. It loads base configurations first,
  /// then merges environment-specific overrides.
  void _loadConfigurations() {
    final configDir = Directory(_configPath);
    if (!configDir.existsSync()) {
      throw ConfigException('Configuration directory not found: $_configPath');
    }

    // Load base configurations
    _loadConfigsFromDirectory(configDir);

    // Load environment-specific configurations
    final envDir = Directory('$_configPath/${_environment.toString()}');
    if (envDir.existsSync()) {
      _loadConfigsFromDirectory(envDir, isEnvironmentSpecific: true);
    }
  }

  /// Loads configuration files from a specific directory.
  ///
  /// [isEnvironmentSpecific] indicates whether these are environment overrides
  /// that should be merged with existing base configurations.
  void _loadConfigsFromDirectory(Directory directory,
      {bool isEnvironmentSpecific = false,}) {
    for (final entity in directory.listSync()) {
      if (entity is File &&
          (entity.path.endsWith('.json') || entity.path.endsWith('.yaml'))) {
        final name = _getConfigName(entity.path);
        final content = entity.readAsStringSync();
        final Map<String, dynamic> configData;

        if (entity.path.endsWith('.json')) {
          configData = jsonDecode(content) as Map<String, dynamic>;
        } else {
          // For YAML support, you would need to add a YAML parser dependency
          // and implement parsing here
          throw ConfigException('YAML parsing not implemented yet');
        }

        if (isEnvironmentSpecific && _config.containsKey(name)) {
          // Merge with base configuration
          _mergeConfigs(_config[name] as Map<String, dynamic>, configData);
        } else {
          _config[name] = configData;
        }

        // Update cache timestamp
        _cacheTimestamps[name] = DateTime.now();
      }
    }
  }

  /// Extracts the configuration name from a file path.
  ///
  /// For example, `/path/to/config/app.json` becomes `app`.
  String _getConfigName(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return fileName.split('.').first;
  }

  /// Recursively merges environment-specific configuration with base configuration.
  ///
  /// Nested objects are merged recursively, while primitive values are replaced.
  void _mergeConfigs(Map<String, dynamic> base, Map<String, dynamic> override) {
    for (final key in override.keys) {
      if (base[key] is Map && override[key] is Map) {
        _mergeConfigs(base[key] as Map<String, dynamic>,
            override[key] as Map<String, dynamic>,);
      } else {
        base[key] = override[key];
      }
    }
  }

  /// Retrieves a configuration value using dot notation.
  ///
  /// Supports nested access with dot notation (e.g., `app.database.host`).
  /// Returns [defaultValue] if the key doesn't exist or has wrong type.
  ///
  /// If caching is enabled, automatically reloads expired configurations.
  ///
  /// ```dart
  /// final host = config.get<String>('database.host', 'localhost');
  /// final port = config.get<int>('app.port', 3000);
  /// final debug = config.get<bool>('app.debug', false);
  /// ```
  @override
  T? get<T>(String key, [T? defaultValue]) {
    // Check if cache is expired or if caching is disabled (always check file modification)
    final parts = key.split('.');
    final configName = parts.first;

    if (_useCache) {
      if (_cacheTimestamps.containsKey(configName)) {
        final timestamp = _cacheTimestamps[configName]!;
        if (DateTime.now().difference(timestamp) > _cacheTtl) {
          // Cache expired, reload this config
          _reloadConfig(configName);
        }
      }
    } else {
      // When caching is disabled, always check if file has been modified
      final baseFile = File('$_configPath/$configName.json');
      if (baseFile.existsSync()) {
        final fileStat = baseFile.statSync();
        final fileModified = fileStat.modified;

        if (!_cacheTimestamps.containsKey(configName) ||
            fileModified.isAfter(_cacheTimestamps[configName]!)) {
          // File has been modified, reload this config
          _reloadConfig(configName);
        }
      }
    }

    // Continue with the rest of the method...

    if (!_config.containsKey(configName)) {
      return defaultValue;
    }

    var current = _config[configName];
    for (var i = 1; i < parts.length; i++) {
      if (current is! Map<String, dynamic>) {
        return defaultValue;
      }

      if (!current.containsKey(parts[i])) {
        return defaultValue;
      }

      current = current[parts[i]];
    }

    if (current is T) {
      return current;
    }

    return defaultValue;
  }

  /// Sets a configuration value using dot notation.
  ///
  /// Creates nested objects as needed. Useful for runtime configuration
  /// overrides or dynamic settings.
  ///
  /// ```dart
  /// config.set('app.api_key', 'secret-key');
  /// config.set('cache.enabled', true);
  /// config.set('database.connections.max', 10);
  /// ```
  ///
  /// Throws [ConfigException] if trying to set a nested property on a
  /// non-object value.
  @override
  void set(String key, dynamic value) {
    final parts = key.split('.');
    final configName = parts.first;

    if (!_config.containsKey(configName)) {
      _config[configName] = <String, dynamic>{};
    }

    var current = _config[configName];
    for (var i = 1; i < parts.length - 1; i++) {
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(parts[i])) {
          current[parts[i]] = <String, dynamic>{};
        }
        current = current[parts[i]];
      } else {
        throw ConfigException('Cannot set nested property on non-object value');
      }
    }

    if (current is Map<String, dynamic>) {
      current[parts.last] = value;
      _cacheTimestamps[configName] = DateTime.now();
    } else {
      throw ConfigException('Cannot set property on non-object value');
    }
  }

  /// Checks if a configuration key exists.
  ///
  /// Returns `true` if the key exists in the configuration, regardless
  /// of its value (including null).
  ///
  /// ```dart
  /// if (config.has('database.url')) {
  ///   final url = config.get<String>('database.url');
  /// }
  /// ```
  @override
  bool has(String key) {
    final parts = key.split('.');
    final configName = parts.first;

    if (!_config.containsKey(configName)) {
      return false;
    }

    var current = _config[configName];
    for (var i = 1; i < parts.length; i++) {
      if (current is! Map<String, dynamic> || !current.containsKey(parts[i])) {
        return false;
      }
      current = current[parts[i]];
    }

    return true;
  }

  /// Returns a copy of all configuration data.
  ///
  /// The returned map is a shallow copy. Modifications to nested objects
  /// will affect the original configuration.
  ///
  /// ```dart
  /// final all = config.all();
  /// print('Available configs: ${all.keys}');
  /// ```
  @override
  Map<String, dynamic> all() {
    return Map<String, dynamic>.from(_config);
  }

  /// Returns a specific configuration section.
  ///
  /// Returns `null` if the section doesn't exist or isn't an object.
  ///
  /// ```dart
  /// final appConfig = config.section('app');
  /// if (appConfig != null) {
  ///   print('App name: ${appConfig['name']}');
  /// }
  /// ```
  @override
  Map<String, dynamic>? section(String name) {
    if (!_config.containsKey(name)) {
      return null;
    }

    final section = _config[name];
    if (section is Map<String, dynamic>) {
      return Map<String, dynamic>.from(section);
    }

    return null;
  }

  /// Reloads a specific configuration section from disk.
  ///
  /// Used internally when cache expires. Reloads both base and
  /// environment-specific versions of the configuration.
  void _reloadConfig(String configName) {
    final baseFile = File('$_configPath/$configName.json');
    final envFile = File('$_configPath/$_environment/$configName.json');

    if (baseFile.existsSync()) {
      final content = baseFile.readAsStringSync();
      _config[configName] = jsonDecode(content);

      if (envFile.existsSync()) {
        final envContent = envFile.readAsStringSync();
        final envConfig = jsonDecode(envContent);
        _mergeConfigs(_config[configName] as Map<String, dynamic>,
            envConfig as Map<String, dynamic>,);
      }

      _cacheTimestamps[configName] = DateTime.now();
    }
  }

  /// Reloads all configuration files from disk.
  ///
  /// Clears all cached data and reloads everything from the filesystem.
  /// Useful when configuration files have been modified externally.
  ///
  /// ```dart
  /// config.reload(); // Refresh all configurations
  /// ```
  @override
  void reload() {
    _config.clear();
    _cacheTimestamps.clear();
    _loadConfigurations();
  }

  /// Loads configuration data from a registry map.
  ///
  /// Useful for loading configurations from external sources or
  /// for testing purposes.
  ///
  /// ```dart
  /// final registry = {
  ///   'app': {'name': 'MyApp', 'version': '1.0'},
  ///   'database': {'host': 'localhost'},
  /// };
  /// config.loadFromRegistry(registry);
  /// ```
  @override
  void loadFromRegistry(Map<String, Map<String, dynamic>> registry) {
    _config.addAll(registry);
  }
}

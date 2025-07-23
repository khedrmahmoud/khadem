import 'dart:convert';
import 'dart:io';

import '../../contracts/config/config_contract.dart';
import '../../support/exceptions/config_exception.dart';

/// The default configuration system used in Khadem.
///
/// Supports:
/// - Loading base and environment-specific config files (from JSON).
/// - Dot notation access (e.g., `app.name`)
/// - Automatic reloading with cache support.
/// - Runtime overrides and dynamic merging.
///
/// Files should be structured like:
/// - `config/app.json`
/// - `config/development/app.json` (overrides for `development` env)
class ConfigSystem implements ConfigInterface {
  // internal storage
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

  /// Create a new configuration system.
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

   void setEnvironment(String environment) {
    _environment.clear();
    _environment.write(environment);
    _loadConfigurations();
  }

  /// Loads all configuration files.
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

  /// Loads configuration files from a directory.
  void _loadConfigsFromDirectory(Directory directory,
      {bool isEnvironmentSpecific = false}) {
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
  String _getConfigName(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return fileName.split('.').first;
  }

  /// Merges environment-specific configuration with base configuration.
  void _mergeConfigs(Map<String, dynamic> base, Map<String, dynamic> override) {
    for (final key in override.keys) {
      if (base[key] is Map && override[key] is Map) {
        _mergeConfigs(base[key] as Map<String, dynamic>,
            override[key] as Map<String, dynamic>);
      } else {
        base[key] = override[key];
      }
    }
  }

  /// Gets a configuration value using dot notation.
  @override
  T? get<T>(String key, [T? defaultValue]) {
    // Check if cache is expired
    if (_useCache) {
      final parts = key.split('.');
      final configName = parts.first;

      if (_cacheTimestamps.containsKey(configName)) {
        final timestamp = _cacheTimestamps[configName]!;
        if (DateTime.now().difference(timestamp) > _cacheTtl) {
          // Cache expired, reload this config
          _reloadConfig(configName);
        }
      }
    }

    final parts = key.split('.');
    final configName = parts.first;

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

  /// Gets all configuration values.
  @override
  Map<String, dynamic> all() {
    return Map<String, dynamic>.from(_config);
  }

  /// Gets a specific configuration section.
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

  /// Reloads a specific configuration section.
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
            envConfig as Map<String, dynamic>);
      }

      _cacheTimestamps[configName] = DateTime.now();
    }
  }

  /// Reloads all configuration files.
  @override
  void reload() {
    _config.clear();
    _cacheTimestamps.clear();
    _loadConfigurations();
  }

  @override
  void loadFromRegistry(Map<String, Map<String, dynamic>> registry) {
    _config.addAll(registry);
  }
}

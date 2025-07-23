import 'dart:io';

import '../../contracts/env/env_interface.dart';

/// The default environment variable manager used by Khadem.
///
/// Supports:
/// - `.env` file loading
/// - Type casting (int, bool, double, list)
/// - Variable substitution (e.g., `$APP_NAME` or `${APP_NAME}`)
/// - Process environment fallback
class EnvSystem implements EnvInterface {
  final Map<String, String> _env = {};
  final List<String> _loadedFiles = [];
  final bool _useProcessEnv;

  /// Creates a new environment system.
  EnvSystem({bool useProcessEnv = true}) : _useProcessEnv = useProcessEnv {
    if (_useProcessEnv) {
      _loadFromProcessEnv();
    }
    loadFromFile('.env');
  }

  /// Loads environment variables from the process environment.
  void _loadFromProcessEnv() {
    _env.addAll(Platform.environment);
  }

  /// Loads environment variables from a file.
  @override
  void loadFromFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return;
    }

    _loadedFiles.add(path);

    for (final line in file.readAsLinesSync()) {
      final trimmedLine = line.trim();

      // Skip empty lines and comments
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue;
      }

      // Handle export statements
      if (trimmedLine.startsWith('export ')) {
        final exportLine = trimmedLine.substring(7).trim();
        _parseEnvLine(exportLine);
        continue;
      }

      _parseEnvLine(trimmedLine);
    }
  }

  /// Parses an environment variable line.
  void _parseEnvLine(String line) {
    // Find the first equals sign that's not escaped
    final equalsIndex = _findUnescapedChar(line, '=');
    if (equalsIndex == -1) return;

    final key = line.substring(0, equalsIndex).trim();
    var value = line.substring(equalsIndex + 1).trim();

    // Remove quotes if present
    if ((value.startsWith('\'') && value.endsWith('\'')) ||
        (value.startsWith('"') && value.endsWith('"'))) {
      value = value.substring(1, value.length - 1);
    }

    // Handle variable substitution
    value = _substituteVariables(value);

    _env[key] = value;
  }

  /// Finds the first unescaped occurrence of a character in a string.
  int _findUnescapedChar(String str, String char) {
    bool escaped = false;
    for (var i = 0; i < str.length; i++) {
      if (str[i] == '\\') {
        escaped = !escaped;
      } else {
        if (!escaped && str[i] == char) {
          return i;
        }
        escaped = false;
      }
    }
    return -1;
  }

  /// Substitutes environment variables in a string.
  String _substituteVariables(String value) {
    final regex = RegExp(r'\$\{([^}]+)\}|\$([a-zA-Z0-9_]+)');
    return value.replaceAllMapped(regex, (match) {
      final varName = match.group(1) ?? match.group(2)!;
      return _env[varName] ?? '';
    });
  }

  @override
  String? get(String key) => _env[key];

  @override
  String getOrDefault(String key, String defaultValue) =>
      _env[key] ?? defaultValue;

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    final value = _env[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    final value = _env[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = _env[key];
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  @override
  List<String> getList(String key,
      {String separator = ',', List<String> defaultValue = const []}) {
    final value = _env[key];
    if (value == null || value.isEmpty) return defaultValue;
    return value.split(separator).map((e) => e.trim()).toList();
  }

  @override
  void set(String key, String value) {
    _env[key] = value;
  }

  @override
  bool has(String key) => _env.containsKey(key);

  @override
  Map<String, String> all() => Map.unmodifiable(_env);

  @override
  List<String> get loadedFiles => List.unmodifiable(_loadedFiles);

  @override
  void clear() {
    _env.clear();
    _loadedFiles.clear();

    if (_useProcessEnv) {
      _loadFromProcessEnv();
    }
  }

  @override
  List<String> validateRequired(List<String> requiredKeys) {
    final missing = <String>[];
    for (final key in requiredKeys) {
      if (!has(key) || _env[key]!.isEmpty) {
        missing.add(key);
      }
    }
    return missing;
  }
}

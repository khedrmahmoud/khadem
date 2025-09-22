import 'dart:io';

import '../../contracts/env/env_interface.dart';

/// The default environment variable manager used by Khadem.
///
/// The EnvSystem provides a comprehensive environment variable management system
/// that supports loading from `.env` files, process environment variables, type casting,
/// and variable substitution. It's designed to be flexible and easy to use in various
/// application contexts.
///
/// ## Features
///
/// - **File Loading**: Automatically loads `.env` files with support for comments,
///   export statements, and various quote styles
/// - **Type Casting**: Converts string values to bool, int, double, and List types
/// - **Variable Substitution**: Supports `$VAR` and `${VAR}` syntax for referencing
///   other environment variables
/// - **Process Environment**: Can optionally load system environment variables
/// - **Validation**: Provides methods to validate required environment variables
///
/// ## Usage
///
/// ```dart
/// // Create a new environment system
/// final env = EnvSystem();
///
/// // Load additional env files
/// env.loadFromFile('.env.local');
///
/// // Get values with type conversion
/// final port = env.getInt('PORT', defaultValue: 3000);
/// final debug = env.getBool('DEBUG', defaultValue: false);
/// final hosts = env.getList('ALLOWED_HOSTS', separator: ';');
///
/// // Set values programmatically
/// env.set('API_KEY', 'secret-key');
///
/// // Validate required variables
/// final missing = env.validateRequired(['DATABASE_URL', 'API_KEY']);
/// if (missing.isNotEmpty) {
///   throw Exception('Missing required env vars: $missing');
/// }
/// ```
///
/// ## .env File Format
///
/// The system supports standard `.env` file syntax:
///
/// ```env
/// # Comments are supported
/// APP_NAME=MyApp
/// APP_VERSION=1.0.0
/// DEBUG=true
/// PORT=3000
///
/// # Quotes are optional but recommended for complex values
/// DATABASE_URL="postgresql://user:pass@localhost:5432/db"
///
/// # Export statements are supported
/// export REDIS_URL=redis://localhost:6379
///
/// # Variable substitution
/// API_BASE_URL=http://localhost:$PORT
/// FULL_NAME="${APP_NAME} v${APP_VERSION}"
/// ```
class EnvSystem implements EnvInterface {
  /// Internal storage for environment variables.
  final Map<String, String> _env = {};

  /// List of files that have been loaded.
  final List<String> _loadedFiles = [];

  /// Whether to load process environment variables.
  final bool _useProcessEnv;

  /// Creates a new environment system.
  ///
  /// [useProcessEnv] determines whether to load system environment variables
  /// as a fallback. Defaults to `true`.
  ///
  /// Automatically loads `.env` file if it exists.
  ///
  /// ```dart
  /// final env = EnvSystem(); // Loads process env + .env
  /// final env = EnvSystem(useProcessEnv: false); // Only .env
  /// ```
  EnvSystem({bool useProcessEnv = true}) : _useProcessEnv = useProcessEnv {
    if (_useProcessEnv) {
      _loadFromProcessEnv();
    }
    loadFromFile('.env');
  }

  /// Loads environment variables from the process environment.
  ///
  /// This method is called automatically during initialization if
  /// [useProcessEnv] is true.
  void _loadFromProcessEnv() {
    _env.addAll(Platform.environment);
  }

  /// Loads environment variables from a file.
  ///
  /// Supports standard `.env` file format with the following features:
  /// - Comments (lines starting with #)
  /// - Export statements (`export KEY=value`)
  /// - Quoted values (single and double quotes)
  /// - Variable substitution (`$VAR` or `${VAR}`)
  /// - Escaped characters
  ///
  /// If the file doesn't exist, this method returns silently.
  ///
  /// ```dart
  /// env.loadFromFile('.env.local');
  /// env.loadFromFile('config/production.env');
  /// ```
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
  ///
  /// Handles the parsing of individual lines from .env files, including:
  /// - Key-value extraction
  /// - Quote removal
  /// - Variable substitution
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

    // Unescape characters
    value = _unescapeString(value);

    // Handle variable substitution
    value = _substituteVariables(value);

    _env[key] = value;
  }

  /// Finds the first unescaped occurrence of a character in a string.
  ///
  /// Used to properly handle escaped characters in .env file parsing.
  /// For example, in `KEY=VALUE\=WITH_EQUALS`, the equals sign after
  /// the backslash should not be treated as a separator.
  int _findUnescapedChar(String str, String char) {
    for (var i = 0; i < str.length; i++) {
      if (str[i] == char) {
        // Check if this character is escaped by counting preceding backslashes
        var backslashCount = 0;
        var j = i - 1;
        while (j >= 0 && str[j] == '\\') {
          backslashCount++;
          j--;
        }
        // If even number of backslashes, the character is not escaped
        if (backslashCount % 2 == 0) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Substitutes environment variables in a string.
  ///
  /// Supports two syntaxes:
  /// - `$VAR` - Simple variable substitution
  /// - `${VAR}` - Bracketed variable substitution (useful for complex cases)
  ///
  /// If a variable is not found, it defaults to an empty string.
  ///
  /// ```dart
  /// // With APP_NAME="MyApp" and VERSION="1.0"
  /// _substituteVariables("Welcome to $APP_NAME v$VERSION")
  /// // Returns: "Welcome to MyApp v1.0"
  /// ```
  String _substituteVariables(String value) {
    final regex = RegExp(r'\$\{([^}]+)\}|\$([a-zA-Z0-9_]+)');
    return value.replaceAllMapped(regex, (match) {
      final varName = match.group(1) ?? match.group(2)!;
      return _env[varName] ?? '';
    });
  }

  /// Unescapes special characters in a string.
  ///
  /// Handles common escape sequences like:
  /// - `\\` becomes `\`
  /// - `\"` becomes `"`
  /// - `\'` becomes `'`
  /// - `\n` becomes newline
  /// - `\t` becomes tab
  String _unescapeString(String value) {
    return value.replaceAllMapped(RegExp(r'\\(.)'), (match) {
      final char = match.group(1)!;
      switch (char) {
        case 'n':
          return '\n';
        case 't':
          return '\t';
        case 'r':
          return '\r';
        case '\\':
          return '\\';
        case '"':
          return '"';
        case "'":
          return "'";
        default:
          return char; // For unknown escapes, just return the character
      }
    });
  }

  /// Retrieves the value of an environment variable.
  ///
  /// Returns `null` if the variable is not set.
  ///
  /// ```dart
  /// final apiKey = env.get('API_KEY');
  /// if (apiKey != null) {
  ///   // Use the API key
  /// }
  /// ```
  @override
  String? get(String key) => _env[key];

  /// Retrieves the value of an environment variable with a default fallback.
  ///
  /// If the variable is not set or is empty, returns [defaultValue].
  ///
  /// ```dart
  /// final dbHost = env.getOrDefault('DB_HOST', 'localhost');
  /// ```
  @override
  String getOrDefault(String key, String defaultValue) =>
      _env[key] ?? defaultValue;

  /// Retrieves a boolean value from an environment variable.
  ///
  /// Recognizes the following truthy values (case-insensitive):
  /// - `true`, `1`, `yes`
  ///
  /// All other values are considered falsy.
  ///
  /// ```dart
  /// final debug = env.getBool('DEBUG', defaultValue: false);
  /// final verbose = env.getBool('VERBOSE'); // defaults to false
  /// ```
  @override
  bool getBool(String key, {bool defaultValue = false}) {
    final value = _env[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Retrieves an integer value from an environment variable.
  ///
  /// If the value cannot be parsed as an integer, returns [defaultValue].
  ///
  /// ```dart
  /// final port = env.getInt('PORT', defaultValue: 3000);
  /// final timeout = env.getInt('TIMEOUT'); // defaults to 0
  /// ```
  @override
  int getInt(String key, {int defaultValue = 0}) {
    final value = _env[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Retrieves a double value from an environment variable.
  ///
  /// If the value cannot be parsed as a double, returns [defaultValue].
  ///
  /// ```dart
  /// final rate = env.getDouble('EXCHANGE_RATE', defaultValue: 1.0);
  /// final threshold = env.getDouble('THRESHOLD'); // defaults to 0.0
  /// ```
  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = _env[key];
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  /// Retrieves a list of strings from an environment variable.
  ///
  /// Splits the value using the specified [separator] and trims whitespace
  /// from each element.
  ///
  /// ```dart
  /// // With ALLOWED_HOSTS="localhost,127.0.0.1,::1"
  /// final hosts = env.getList('ALLOWED_HOSTS');
  /// // Returns: ['localhost', '127.0.0.1', '::1']
  ///
  /// // With semicolon separator
  /// final paths = env.getList('PATHS', separator: ';');
  /// ```
  @override
  List<String> getList(
    String key, {
    String separator = ',',
    List<String> defaultValue = const [],
  }) {
    final value = _env[key];
    if (value == null || value.isEmpty) return defaultValue;
    return value.split(separator).map((e) => e.trim()).toList();
  }

  /// Sets the value of an environment variable.
  ///
  /// This method allows programmatically setting environment variables,
  /// which can be useful for testing or dynamic configuration.
  ///
  /// ```dart
  /// env.set('API_KEY', 'secret-key');
  /// env.set('DEBUG', 'true');
  /// ```
  @override
  void set(String key, String value) {
    _env[key] = value;
  }

  /// Checks if an environment variable is set.
  ///
  /// Returns `true` if the variable exists, regardless of its value.
  ///
  /// ```dart
  /// if (env.has('DATABASE_URL')) {
  ///   // Database is configured
  /// }
  /// ```
  @override
  bool has(String key) => _env.containsKey(key);

  /// Returns a copy of all environment variables.
  ///
  /// The returned map is unmodifiable to prevent external modifications.
  ///
  /// ```dart
  /// final allVars = env.all();
  /// for (final entry in allVars.entries) {
  ///   print('${entry.key}=${entry.value}');
  /// }
  /// ```
  @override
  Map<String, String> all() => Map.unmodifiable(_env);

  /// Returns a list of all loaded environment files.
  ///
  /// This includes the default `.env` file and any additional files
  /// loaded via [loadFromFile].
  ///
  /// ```dart
  /// final files = env.loadedFiles;
  /// print('Loaded files: $files');
  /// ```
  @override
  List<String> get loadedFiles => List.unmodifiable(_loadedFiles);

  /// Clears all environment variables and loaded files.
  ///
  /// If [useProcessEnv] was true during initialization, process
  /// environment variables will be reloaded.
  ///
  /// ```dart
  /// env.clear(); // Reset to initial state
  /// ```
  @override
  void clear() {
    _env.clear();
    _loadedFiles.clear();

    if (_useProcessEnv) {
      _loadFromProcessEnv();
    }
  }

  /// Validates that all required environment variables are set.
  ///
  /// Returns a list of missing or empty required variables.
  /// An empty list indicates all required variables are present.
  ///
  /// ```dart
  /// final missing = env.validateRequired(['DATABASE_URL', 'API_KEY']);
  /// if (missing.isNotEmpty) {
  ///   throw Exception('Missing required env vars: $missing');
  /// }
  /// ```
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

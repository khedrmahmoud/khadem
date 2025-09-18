import 'dart:convert';
import 'dart:io';

import '../../contracts/lang/lang_provider.dart';

/// A [LangProvider] implementation that loads translations from a directory.
///
/// This class supports loading translations from a directory named "lang" in the
/// root of the project. Inside the "lang" directory, there should be a set of
/// subdirectories, each named after a locale (e.g. "en", "fr", "de", etc.). Each
/// of these directories should contain a set of JSON files, each containing a
/// set of key-value pairs. The keys will be used to look up translations, and
/// the values will be the translations themselves.
///
/// ## Directory Structure
///
/// ```
/// project_root/
/// └── lang/
///     ├── en/
///     │   ├── messages.json
///     │   ├── validation.json
///     │   └── fields.json
///     ├── fr/
///     │   ├── messages.json
///     │   ├── validation.json
///     │   └── fields.json
///     └── es/
///         ├── messages.json
///         └── validation.json
/// ```
///
/// ## JSON File Format
///
/// Each JSON file contains key-value pairs:
/// ```json
/// {
///   "greeting": "Hello :name!",
///   "items": "item|items",
///   "welcome": "Welcome to :app",
///   "error_required": "The :field field is required.",
///   "apples": "You have :count apple|You have :count apples"
/// }
/// ```
///
/// ## Features
///
/// - **Automatic loading**: Translations are loaded on-demand when first accessed.
/// - **Fallback support**: Falls back to fallback locale if translation not found.
/// - **Namespace support**: Load translations for specific packages or modules.
/// - **Parameter replacement**: Replace :param placeholders with values.
/// - **Pluralization**: Handle singular/plural forms with | separator.
/// - **Custom replacers**: Add custom logic for parameter replacement.
/// - **Caching**: Cache loaded translations to improve performance.
///
/// ## Usage Examples
///
/// ```dart
/// final provider = FileLangProvider();
/// provider.setLocale('en');
/// provider.setFallbackLocale('en');
///
/// // Basic translation
/// String greeting = provider.t('messages.greeting', parameters: {'name': 'Alice'});
///
/// // Pluralization
/// String apples = provider.choice('apples', 3, parameters: {'count': 3});
///
/// // Field translation
/// String label = provider.field('email');
///
/// // Namespace loading
/// provider.loadNamespace('auth', 'en', {'login': 'Sign In'});
/// String login = provider.t('login', namespace: 'auth');
/// ```
///
/// ## Parameter Replacement
///
/// The provider supports multiple parameter replacement strategies:
///
/// 1. **Standard replacement**: `:param` is replaced with the parameter value.
/// 2. **Custom replacers**: Add functions for complex formatting.
/// 3. **Nested parameters**: Parameters can contain objects for complex logic.
///
/// ## Pluralization Rules
///
/// - `item|items` → "item" for count=1, "items" for count≠1
/// - `apple|apples` → "apple" for count=1, "apples" for count≠1
/// - Works with parameters: `:count item|:count items`
///
/// ## Performance Notes
///
/// - Translations are cached after first load.
/// - Use [clearCache] to force reload after file changes.
/// - Large translation files are loaded entirely into memory.
class FileLangProvider implements LangProvider {
  /// The translations for each locale and namespace.
  /// Map structure: locale -> namespace -> key -> value
  final Map<String, Map<String, Map<String, String>>> _translations = {};

  /// The current locale.
  String _currentLocale = 'en';

  /// The fallback locale.
  String _fallbackLocale = 'en';

  /// Custom parameter replacers.
  final List<String Function(String key, dynamic value, Map<String, dynamic> parameters)> _replacers = [];

  /// Cache for loaded locales to avoid re-reading files.
  final Set<String> _loadedLocales = {};

  /// Sets the current locale.
  ///
  /// If the locale is not available, it will fall back to the fallback locale.
  @override
  void setLocale(String locale) {
    _currentLocale = locale;
    if (!_loadedLocales.contains(locale)) {
      _loadLocale(locale);
    }
    if (!_translations.containsKey(locale)) {
      _currentLocale = _fallbackLocale;
    }
  }

  @override
  String getLocale() => _currentLocale;

  @override
  void setFallbackLocale(String locale) {
    _fallbackLocale = locale;
  }

  @override
  String getFallbackLocale() => _fallbackLocale;

  /// Looks up a translation for the given key with advanced parameter replacement.
  ///
  /// Supports multiple parameters using :param syntax, custom replacers,
  /// and namespace lookup.
  @override
  String t(String key, {
    Map<String, dynamic>? parameters,
    String? locale,
    String? namespace,
  }) {
    final loc = locale ?? _currentLocale;
    final ns = namespace ?? '';

    // Try namespace first, then global
    String? msg = _getTranslation(key, loc, ns) ?? _getTranslation(key, loc, '');

    // Fallback to fallback locale
    if (msg == null && loc != _fallbackLocale) {
      msg = _getTranslation(key, _fallbackLocale, ns) ?? _getTranslation(key, _fallbackLocale, '');
    }

    // Use key if not found
    msg ??= key;

    // Apply parameter replacement
    if (parameters != null) {
      msg = _replaceParameters(msg, parameters);
    }

    return msg;
  }

  /// Translates with pluralization based on count.
  @override
  String choice(String key, int count, {
    Map<String, dynamic>? parameters,
    String? locale,
    String? namespace,
  }) {
    final loc = locale ?? _currentLocale;
    final ns = namespace ?? '';

    String? msg = _getTranslation(key, loc, ns) ?? _getTranslation(key, loc, '');

    if (msg == null && loc != _fallbackLocale) {
      msg = _getTranslation(key, _fallbackLocale, ns) ?? _getTranslation(key, _fallbackLocale, '');
    }

    msg ??= key;

    // Handle pluralization
    if (msg.contains('|')) {
      final parts = msg.split('|');
      msg = count == 1 ? parts[0] : (parts.length > 1 ? parts[1] : parts[0]);
    }

    // Add count to parameters
    final params = Map<String, dynamic>.from(parameters ?? {});
    params['count'] = count;

    return _replaceParameters(msg, params);
  }

  /// Looks up a field translation.
  @override
  String field(String key, {String? locale, String? namespace}) {
    return t('fields.$key', locale: locale, namespace: namespace);
  }

  @override
  bool has(String key, {String? locale, String? namespace}) {
    final loc = locale ?? _currentLocale;
    final ns = namespace ?? '';
    return _getTranslation(key, loc, ns) != null ||
           _getTranslation(key, loc, '') != null ||
           (loc != _fallbackLocale && (_getTranslation(key, _fallbackLocale, ns) != null ||
                                       _getTranslation(key, _fallbackLocale, '') != null));
  }

  @override
  String? get(String key, {String? locale, String? namespace}) {
    final loc = locale ?? _currentLocale;
    final ns = namespace ?? '';
    return _getTranslation(key, loc, ns) ??
           _getTranslation(key, loc, '') ??
           (loc != _fallbackLocale ? (_getTranslation(key, _fallbackLocale, ns) ??
                                      _getTranslation(key, _fallbackLocale, '')) : null);
  }

  @override
  void loadNamespace(String namespace, String locale, Map<String, String> translations) {
    _translations.putIfAbsent(locale, () => {});
    _translations[locale]![namespace] = Map.from(translations);
  }

  @override
  void clearCache() {
    _loadedLocales.clear();
    _translations.clear();
  }

  @override
  List<String> getAvailableLocales() {
    if (_translations.isNotEmpty) {
      return _translations.keys.toList();
    }
    
    final dir = Directory('lang');
    if (!dir.existsSync()) return ['en'];

    return dir.listSync()
        .whereType<Directory>()
        .map((d) => d.path.split(Platform.pathSeparator).last)
        .toList();
  }

  @override
  void addParameterReplacer(String Function(String key, dynamic value, Map<String, dynamic> parameters) replacer) {
    _replacers.add(replacer);
  }

  /// Gets a translation from the internal map.
  String? _getTranslation(String key, String locale, String namespace) {
    return _translations[locale]?[namespace]?[key];
  }

  /// Replaces parameters in the message using :param syntax and custom replacers.
  String _replaceParameters(String message, Map<String, dynamic> parameters) {
    String result = message;

    // First apply custom replacers to get replacement values
    final customReplacements = <String, String>{};
    for (final replacer in _replacers) {
      for (final entry in parameters.entries) {
        final replacement = replacer(entry.key, entry.value, parameters);
        if (replacement != ':${entry.key}') { // Only use if replacer actually did something
          customReplacements[entry.key] = replacement;
        }
      }
    }

    // Standard :param replacement
    for (final entry in parameters.entries) {
      final placeholder = ':${entry.key}';
      final replacement = customReplacements[entry.key] ?? entry.value.toString();
      result = result.replaceAll(placeholder, replacement);
    }

    return result;
  }

  /// Loads the translations for the given locale.
  ///
  /// The method will look for a directory named after the locale in the "lang"
  /// directory. Inside the directory, it will look for JSON files.
  void _loadLocale(String locale) {
    final dir = Directory('lang/$locale');
    if (!dir.existsSync()) return;

    _loadedLocales.add(locale);
    _translations[locale] ??= {};

    for (final file in dir.listSync().whereType<File>()) {
      if (file.path.endsWith('.json')) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content) as Map<String, dynamic>;

        // Load into global namespace by default
        final translations = Map<String, String>.from(data.map(
          (k, v) => MapEntry(k, v.toString()),
        ));

        _translations[locale]![''] = translations;
      }
    }
  }
}

import '../../contracts/lang/lang_provider.dart';
import '../http/context/request_context.dart';
import 'file_lang_provider.dart';

/// Class used to translate strings with the currently set locale.
///
/// This class is the main entry point to translate strings with the currently set
/// locale. It uses a [LangProvider] to load and access the translations.
///
/// The [LangProvider] can be changed with the [use] method. This is useful in
/// tests or advanced use cases where a different provider is needed.
///
/// The current request locale can be changed with the [setRequestLocale] method.
/// This method changes the locale for all future calls to [t] and [getField].
///
/// The [t] method translates a key with optional parameters.
/// The [choice] method handles pluralization.
/// The [getField] method translates a field label.
///
/// ## Advanced Features
///
/// - **Parameter replacement** with :param syntax
/// - **Pluralization** with count-based choices
/// - **Namespace support** for packages
/// - **Fallback locales** for missing translations
/// - **Custom parameter replacers** for advanced formatting
/// - **Request-scoped locales** for per-request localization
///
/// ## Basic Usage
///
/// ```dart
/// // Set global locale
/// Lang.setGlobalLocale('en');
/// Lang.setFallbackLocale('en');
///
/// // Basic translation
/// String greeting = Lang.t('messages.greeting');
///
/// // Translation with parameters
/// String welcome = Lang.t('messages.welcome', parameters: {'name': 'Alice'});
///
/// // Pluralization
/// String items = Lang.choice('items.count', 5);
///
/// // Field translation
/// String label = Lang.getField('email');
/// ```
///
/// ## Request-Specific Localization
///
/// ```dart
/// // Set locale for current request
/// Lang.setRequestLocale('fr');
///
/// // All subsequent calls in this request will use French
/// String message = Lang.t('messages.hello'); // Uses French if available
/// ```
///
/// ## Namespace Support
///
/// ```dart
/// // Load package translations
/// Lang.loadNamespace('package:auth', 'en', {'login': 'Sign In'});
///
/// // Use namespaced translation
/// String login = Lang.t('login', namespace: 'package:auth');
/// ```
///
/// ## Custom Parameter Replacers
///
/// ```dart
/// // Add custom replacer for date formatting
/// Lang.addParameterReplacer((key, value, params) {
///   if (key == 'date' && value is DateTime) {
///     return value.toString(); // Custom date formatting
///   }
///   return ':$key'; // Default replacement
/// });
/// ```
class Lang {
  /// The [LangProvider] used to load and access translations.
  static LangProvider _provider = FileLangProvider();

  /// The global locale, separate from request-specific locale
  static String? _globalLocale;

  /// Change the [LangProvider] used.
  ///
  /// This is useful in tests or advanced use cases where a different provider is
  /// needed.
  static void use(LangProvider provider) {
    _provider = provider;
  }

  /// Sets the global locale.
  ///
  /// This method changes the locale for all future calls to [t] and [getField].
  static void setGlobalLocale(String locale) {
    _globalLocale = locale;
    _provider.setLocale(locale);
  }

  /// Gets the current global locale.
  static String getGlobalLocale() => _globalLocale ?? _provider.getLocale();

  /// Sets the fallback locale.
  static void setFallbackLocale(String locale) {
    _provider.setFallbackLocale(locale);
  }

  /// Gets the fallback locale.
  static String getFallbackLocale() => _provider.getFallbackLocale();

  /// Sets the current request locale.
  ///
  /// This method changes the locale for all future calls to [t] and [getField].
  static void setRequestLocale(String locale) {
    RequestContext.set('locale', locale);
  }

  static String? _getLocale({String? overrideLocale}) {
    if (overrideLocale != null) return overrideLocale;
    
    try {
      final requestLocale = RequestContext.get<String?>('locale');
      if (requestLocale != null) return requestLocale;
    } catch (_) {
      // No request context
    }
    
    return _globalLocale;
  }

  /// Translates a key with optional parameters and namespace.
  ///
  /// Supports advanced parameter replacement using :param syntax.
  /// If [namespace] is provided, looks in that namespace first.
  ///
  /// - [key]: The translation key.
  /// - [parameters]: Map of parameters to replace.
  /// - [locale]: Override locale.
  /// - [namespace]: Namespace to search in.
  /// - Returns: The translated string.
  static String t(String key, {
    Map<String, dynamic>? parameters,
    String? locale,
    String? namespace,
  }) {
    return _provider.t(key,
        parameters: parameters,
        locale: _getLocale(overrideLocale: locale),
        namespace: namespace,
    );
  }

  /// Translates with pluralization based on count.
  ///
  /// - [key]: The translation key with plural forms.
  /// - [count]: The count for pluralization.
  /// - [parameters]: Parameters to replace.
  /// - [locale]: Override locale.
  /// - [namespace]: Namespace to search in.
  /// - Returns: The translated string with pluralization.
  static String choice(String key, int count, {
    Map<String, dynamic>? parameters,
    String? locale,
    String? namespace,
  }) {
    return _provider.choice(key, count,
        parameters: parameters,
        locale: _getLocale(overrideLocale: locale),
        namespace: namespace,
    );
  }

  /// Translates a field label.
  ///
  /// - [key]: The field key.
  /// - [locale]: Override locale.
  /// - [namespace]: Namespace to search in.
  /// - Returns: The translated field label.
  static String getField(String field, {String? locale, String? namespace}) {
    return _provider.field(field,
        locale: _getLocale(overrideLocale: locale),
        namespace: namespace,
    );
  }

  /// Checks if a translation key exists.
  ///
  /// - [key]: The translation key.
  /// - [locale]: Override locale.
  /// - [namespace]: Namespace to search in.
  /// - Returns: True if exists.
  static bool has(String key, {String? locale, String? namespace}) {
    return _provider.has(key,
        locale: _getLocale(overrideLocale: locale),
        namespace: namespace,
    );
  }

  /// Gets the raw translation value.
  ///
  /// - [key]: The translation key.
  /// - [locale]: Override locale.
  /// - [namespace]: Namespace to search in.
  /// - Returns: The raw translation or null.
  static String? get(String key, {String? locale, String? namespace}) {
    return _provider.get(key,
        locale: _getLocale(overrideLocale: locale),
        namespace: namespace,
    );
  }

  /// Loads translations for a namespace.
  ///
  /// - [namespace]: The namespace.
  /// - [locale]: The locale.
  /// - [translations]: The translations map.
  static void loadNamespace(String namespace, String locale, Map<String, String> translations) {
    _provider.loadNamespace(namespace, locale, translations);
  }

  /// Clears the translation cache.
  static void clearCache() {
    _provider.clearCache();
  }

  /// Gets all available locales.
  static List<String> getAvailableLocales() => _provider.getAvailableLocales();

  /// Adds a custom parameter replacer.
  static void addParameterReplacer(String Function(String key, dynamic value, Map<String, dynamic> parameters) replacer) {
    _provider.addParameterReplacer(replacer);
  }
}

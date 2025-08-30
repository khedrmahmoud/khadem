/// LangProvider contract that defines the interface for a language provider.
///
/// The LangProvider contract is used to define the interface for a language
/// provider. The language provider is responsible for providing the translations
/// for the application, with advanced features like pluralization, parameter
/// replacement, and context support.
///
/// The LangProvider contract defines the following methods:
///
/// * [setLocale]: Sets the locale for the language provider.
/// * [getLocale]: Gets the current locale.
/// * [setFallbackLocale]: Sets the fallback locale.
/// * [t]: Translates a key with optional parameters and context.
/// * [choice]: Translates with pluralization based on count.
/// * [field]: Translates a field label.
/// * [has]: Checks if a translation key exists.
/// * [get]: Gets raw translation value.
/// * [loadNamespace]: Loads translations for a namespace (e.g., packages).
/// * [clearCache]: Clears any cached translations.
///
/// The [t] method supports advanced parameter replacement using :param syntax.
/// The [choice] method handles plural forms based on count.
/// Namespaces allow organizing translations for different packages or modules.
///
/// ## Example Usage
///
/// ```dart
/// class MyLangProvider implements LangProvider {
///   // Implementation here
/// }
///
/// final provider = MyLangProvider();
/// provider.setLocale('en');
/// provider.setFallbackLocale('en');
///
/// // Basic translation
/// String greeting = provider.t('messages.greeting');
///
/// // Translation with parameters
/// String welcome = provider.t('messages.welcome', parameters: {'name': 'Alice'});
///
/// // Pluralization
/// String items = provider.choice('items.count', 5, parameters: {'count': 5});
///
/// // Field translation
/// String label = provider.field('email');
///
/// // Namespace support
/// provider.loadNamespace('package:auth', 'en', {'login': 'Sign In'});
/// String login = provider.t('login', namespace: 'package:auth');
/// ```
///
/// ## Translation File Structure
///
/// Translation files are typically JSON files organized by locale:
/// ```
/// lang/
/// ├── en/
/// │   ├── messages.json
/// │   └── validation.json
/// └── fr/
///     ├── messages.json
///     └── validation.json
/// ```
///
/// ## Parameter Replacement
///
/// Parameters are replaced using :param syntax:
/// ```json
/// {
///   "welcome": "Hello :name, welcome to :app",
///   "items": "You have :count item|You have :count items"
/// }
/// ```
///
/// ## Pluralization
///
/// Use | to separate singular and plural forms:
/// ```json
/// {
///   "apple": "apple|apples",
///   "item": "item|items"
/// }
/// ```
abstract class LangProvider {
  /// Sets the locale for the language provider.
  ///
  /// The locale is used to translate the keys. Implementations should load
  /// translations for this locale if not already loaded.
  ///
  /// - [locale]: The locale code (e.g., 'en', 'fr', 'ar').
  void setLocale(String locale);

  /// Gets the current locale.
  ///
  /// - Returns: The current locale code.
  String getLocale();

  /// Sets the fallback locale for missing translations.
  ///
  /// When a translation is not found in the current locale, this locale
  /// will be used as a fallback.
  ///
  /// - [locale]: The fallback locale code.
  void setFallbackLocale(String locale);

  /// Gets the fallback locale.
  ///
  /// - Returns: The fallback locale code.
  String getFallbackLocale();

  /// Translates a key with optional parameters, context, and namespace.
  ///
  /// Supports advanced parameter replacement using :param syntax.
  /// If [namespace] is provided, looks in that namespace first.
  /// Falls back to fallback locale if translation not found.
  ///
  /// - [key]: The translation key (e.g., 'validation.required').
  /// - [parameters]: Map of parameters to replace (e.g., {'field': 'email'}).
  /// - [locale]: Override locale; uses current if null.
  /// - [namespace]: Namespace to search in (e.g., 'package:auth').
  /// - Returns: The translated string with parameters replaced.
  String t(String key, {
    Map<String, dynamic>? parameters,
    String? locale,
    String? namespace,
  });

  /// Translates with pluralization based on count.
  ///
  /// Handles singular/plural forms based on the count value.
  /// Expects translation keys with | separator for plural forms.
  ///
  /// Example translation: "item|items" -> "item" for count=1, "items" for count>1
  ///
  /// - [key]: The translation key with plural forms.
  /// - [count]: The count to determine singular/plural.
  /// - [parameters]: Parameters to replace, including :count.
  /// - [locale]: Override locale.
  /// - [namespace]: Namespace to search in.
  /// - Returns: The translated string with pluralization and parameters.
  String choice(String key, int count, {
    Map<String, dynamic>? parameters,
    String? locale,
    String? namespace,
  });

  /// Translates a field label.
  ///
  /// Convenience method for field labels, often used in forms.
  ///
  /// - [key]: The field key (e.g., 'email').
  /// - [locale]: Override locale.
  /// - [namespace]: Namespace to search in.
  /// - Returns: The translated field label.
  String field(String key, {String? locale, String? namespace});

  /// Checks if a translation key exists.
  ///
  /// - [key]: The translation key.
  /// - [locale]: Locale to check; uses current if null.
  /// - [namespace]: Namespace to search in.
  /// - Returns: True if the key exists.
  bool has(String key, {String? locale, String? namespace});

  /// Gets the raw translation value without parameter replacement.
  ///
  /// - [key]: The translation key.
  /// - [locale]: Override locale.
  /// - [namespace]: Namespace to search in.
  /// - Returns: The raw translation string or key if not found.
  String? get(String key, {String? locale, String? namespace});

  /// Loads translations for a specific namespace.
  ///
  /// Useful for loading package-specific translations.
  ///
  /// - [namespace]: The namespace identifier.
  /// - [locale]: Locale to load for.
  /// - [translations]: Map of key-value translations.
  void loadNamespace(String namespace, String locale, Map<String, String> translations);

  /// Clears any cached translations.
  ///
  /// Forces reloading of translations on next access.
  void clearCache();

  /// Gets all available locales.
  ///
  /// - Returns: List of available locale codes.
  List<String> getAvailableLocales();

  /// Adds a custom parameter replacer function.
  ///
  /// Allows extending parameter replacement logic.
  ///
  /// - [replacer]: Function that takes key, value, and parameters, returns replaced string.
  void addParameterReplacer(String Function(String key, dynamic value, Map<String, dynamic> parameters) replacer);
}

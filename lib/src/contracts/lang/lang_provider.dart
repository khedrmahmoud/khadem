/// LangProvider contract that defines the interface for a language provider.
///
/// The LangProvider contract is used to define the interface for a language
/// provider. The language provider is responsible for providing the translations
/// for the application.
///
/// The LangProvider contract defines the following methods:
///
/// * [setLocale]: Sets the locale for the language provider.
/// * [t]: Translates a key with optional field and argument.
/// * [field]: Translates a field label.
///
/// The [t] method takes the following parameters:
///
/// * [key]: The key to translate.
/// * [field]: The field to translate. If not provided, the key will be used.
/// * [arg]: The argument to replace in the translation.
/// * [locale]: The locale to use for translation. If not provided, the locale
///   set in the [setLocale] method will be used.
///
/// The [field] method takes the following parameters:
///
/// * [key]: The key to translate.
/// * [locale]: The locale to use for translation. If not provided, the locale
///   set in the [setLocale] method will be used.
///
/// The LangProvider contract is used by the [Lang] class to provide the
/// translations for the application.
abstract class LangProvider {
  /// Sets the locale for the language provider.
  ///
  /// The locale is used to translate the keys.
  void setLocale(String locale);

  /// Translates a key with optional field and argument.
  ///
  /// The method takes the following parameters:
  ///
  /// * [key]: The key to translate.
  /// * [field]: The field to translate. If not provided, the key will be used.
  /// * [arg]: The argument to replace in the translation.
  /// * [locale]: The locale to use for translation. If not provided, the locale
  ///   set in the [setLocale] method will be used.
  String t(String key, {String field = '', String? arg, String? locale});

  /// Translates a field label.
  ///
  /// The method takes the following parameters:
  ///
  /// * [key]: The key to translate.
  /// * [locale]: The locale to use for translation. If not provided, the locale
  ///   set in the [setLocale] method will be used.
  String field(String key, {String? locale});
}

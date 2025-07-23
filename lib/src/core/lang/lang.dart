import '../../contracts/lang/lang_provider.dart';
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
/// The [t] method translates a key with optional field and argument.
/// The [getField] method translates a field label.
class Lang {
  /// The [LangProvider] used to load and access translations.
  static LangProvider _provider = FileLangProvider();

  /// Change the [LangProvider] used.
  ///
  /// This is useful in tests or advanced use cases where a different provider is
  /// needed.
  static void use(LangProvider provider) {
    _provider = provider;
  }

  /// Sets the current request locale.
  ///
  /// This method changes the locale for all future calls to [t] and [getField].
  static void setRequestLocale(String locale) {
    _provider.setLocale(locale);
  }

  /// Translates a key with optional field and argument.
  ///
  /// If the [field] parameter is not empty, the method will look for a key in
  /// the format `key.field` and will return the translation for that key.
  ///
  /// If the [arg] parameter is not null, the method will replace the `:arg`
  /// placeholder with the value of [arg].
  ///
  /// If the [locale] parameter is not null, the method will use the specified
  /// locale instead of the current request locale.
  static String t(String key,
      {String field = '', String? arg, String? locale}) {
    return _provider.t(key, field: field, arg: arg, locale: locale);
  }

  /// Translates a field label.
  ///
  /// The method will look for a key in the format `field.label` and will return
  /// the translation for that key.
  ///
  /// If the [locale] parameter is not null, the method will use the specified
  /// locale instead of the current request locale.
  static String getField(String field, {String? locale}) {
    return _provider.field(field, locale: locale);
  }
}

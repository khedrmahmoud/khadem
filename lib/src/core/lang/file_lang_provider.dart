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
/// The class will automatically load the translations for the current locale
/// when the [setLocale] method is called. If a translation is not available for
/// a given locale, it will fall back to the translation for the "en" locale.
///
/// The class also supports basic string interpolation, using the syntax
/// ":field" and ":arg". The ":field" placeholder will be replaced with the
/// translation for the given field, and the ":arg" placeholder will be replaced
/// with the given argument.
class FileLangProvider implements LangProvider {
  /// The translations for each locale.
  ///
  /// The map is keyed by locale, and each value is another map that is keyed
  /// by the translation key. The value for each key is the translation itself.
  final Map<String, Map<String, String>> _translations = {};

  /// The current locale.
  String _currentLocale = 'en';

  /// Sets the current locale.
  ///
  /// If the locale is not available, it will fall back to the "en" locale.
  @override
  void setLocale(String locale) {
    _currentLocale = locale;
    if (!_translations.containsKey(locale)) {
      _loadLocale(locale);
    }
    if (!_translations.containsKey(locale)) {
      _currentLocale = 'en';
    }
  }

  /// Looks up a translation for the given key.
  ///
  /// If the translation is not available for the current locale, it will fall
  /// back to the translation for the "en" locale. If the translation is not
  /// available at all, it will return the key itself.
  ///
  /// The method also supports basic string interpolation, using the syntax
  /// ":field" and ":arg". The ":field" placeholder will be replaced with the
  /// translation for the given field, and the ":arg" placeholder will be replaced
  /// with the given argument.
  @override
  String t(String key, {String field = '', String? arg, String? locale}) {
    final loc = locale ?? _currentLocale;
    final msg = _translations[loc]?[key] ?? _translations['en']?[key] ?? key;
    return msg
        .replaceAll(
            ':field', field.isNotEmpty ? this.field(field, locale: loc) : '')
        .replaceAll(':arg', arg ?? '');
  }

  /// Looks up a translation for the given key in the current locale.
  ///
  /// If the translation is not available for the current locale, it will fall
  /// back to the translation for the "en" locale. If the translation is not
  /// available at all, it will return the key itself.
  @override
  String field(String key, {String? locale}) {
    final loc = locale ?? _currentLocale;
    return _translations[loc]?[key] ?? _translations['en']?[key] ?? key;
  }

  /// Loads the translations for the given locale.
  ///
  /// The method will look for a directory named after the locale in the "lang"
  /// directory. Inside the directory, it will look for JSON files, each
  /// containing a set of key-value pairs. The keys will be used to look up
  /// translations, and the values will be the translations themselves.
  void _loadLocale(String locale) {
    final dir = Directory('lang/$locale');
    if (!dir.existsSync()) return;

    _translations[locale] = {};
    for (final file in dir.listSync().whereType<File>()) {
      if (file.path.endsWith('.json')) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content);
        _translations[locale]!.addAll(Map<String, String>.from(data));
      }
    }
  }
}

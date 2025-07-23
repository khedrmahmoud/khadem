mixin HasTranslations {
  Map<String, Map<String, String>> translations = {};

  String? getTranslation(String key, String locale) {
    return translations[locale]?[key];
  }

  void setTranslation(String key, String locale, String value) {
    translations.putIfAbsent(locale, () => {})[key] = value;
  }

  Map<String, String> getAllForLocale(String locale) {
    return translations[locale] ?? {};
  }

  void loadTranslations(Map<String, dynamic> raw) {
    translations = {
      for (final locale in raw.keys)
        locale: Map<String, String>.from(raw[locale] ?? {})
    };
  }

  Map<String, dynamic> toJsonTranslations() {
    return translations;
  }
}

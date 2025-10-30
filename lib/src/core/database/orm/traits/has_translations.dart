/// Mixin that adds multi-language translation support to models
///
/// Store and retrieve translated content for multiple locales.
/// Common use case: multi-language CMS, product descriptions, etc.
///
/// Example:
/// ```dart
/// class Product extends KhademModel<Product> with HasTranslations {
///   @override
///   List<String> get translatableFields => ['name', 'description'];
///
///   @override
///   String get defaultLocale => 'en';
/// }
///
/// // Set translations:
/// final product = Product();
/// product.setTranslation('name', 'en', 'Product Name');
/// product.setTranslation('name', 'ar', 'اسم المنتج');
/// product.setTranslation('description', 'en', 'A great product');
///
/// // Get translations:
/// print(product.getTranslation('name', 'ar')); // "اسم المنتج"
/// print(product.getTranslation('name', 'fr')); // null
/// print(product.getTranslationWithFallback('name', 'fr')); // "Product Name" (falls back to default)
///
/// // Get all translations for a locale:
/// final arTranslations = product.getAllForLocale('ar');
/// print(arTranslations); // {'name': 'اسم المنتج'}
///
/// // Store in JSON column:
/// final json = product.toJsonTranslations();
/// // Save to database: UPDATE products SET translations = json
/// ```
mixin HasTranslations {
  /// Storage for all translations
  /// Structure: { 'locale': { 'field': 'value' } }
  Map<String, Map<String, String>> translations = {};

  /// Override to specify which fields are translatable
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<String> get translatableFields => ['title', 'description', 'content'];
  /// ```
  List<String> get translatableFields => [];

  /// Override to specify the default/fallback locale
  ///
  /// Used when a translation is not available in the requested locale.
  String get defaultLocale => 'en';

  /// Get translation for a specific field and locale
  ///
  /// Returns null if translation doesn't exist.
  String? getTranslation(String field, String locale) {
    return translations[locale]?[field];
  }

  /// Get translation with fallback to default locale
  ///
  /// If translation doesn't exist in requested locale,
  /// falls back to default locale.
  String? getTranslationWithFallback(String field, String locale) {
    // Try requested locale first
    final translation = getTranslation(field, locale);
    if (translation != null) return translation;

    // Fall back to default locale
    if (locale != defaultLocale) {
      return getTranslation(field, defaultLocale);
    }

    return null;
  }

  /// Set translation for a specific field and locale
  void setTranslation(String field, String locale, String value) {
    translations.putIfAbsent(locale, () => {})[field] = value;
  }

  /// Set multiple translations for a locale at once
  ///
  /// Example:
  /// ```dart
  /// product.setTranslationsForLocale('ar', {
  ///   'name': 'اسم المنتج',
  ///   'description': 'وصف المنتج',
  /// });
  /// ```
  void setTranslationsForLocale(String locale, Map<String, String> values) {
    translations.putIfAbsent(locale, () => {}).addAll(values);
  }

  /// Get all translations for a specific locale
  Map<String, String> getAllForLocale(String locale) {
    return translations[locale] ?? {};
  }

  /// Get all available locales
  List<String> getAvailableLocales() {
    return translations.keys.toList();
  }

  /// Check if a translation exists for a field in a locale
  bool hasTranslation(String field, String locale) {
    return translations[locale]?.containsKey(field) ?? false;
  }

  /// Check if any translations exist for a locale
  bool hasLocale(String locale) {
    return translations.containsKey(locale) && translations[locale]!.isNotEmpty;
  }

  /// Load translations from JSON/database
  ///
  /// Expected format: { 'en': { 'name': 'value' }, 'ar': { ... } }
  void loadTranslations(Map<String, dynamic> raw) {
    translations = {
      for (final locale in raw.keys)
        locale: Map<String, String>.from(
          (raw[locale] ?? {}) as Map<dynamic, dynamic>,
        ),
    };
  }

  /// Convert translations to JSON for database storage
  ///
  /// Returns: { 'en': { 'name': 'value' }, 'ar': { ... } }
  Map<String, dynamic> toJsonTranslations() {
    return translations;
  }

  /// Remove all translations for a locale
  void removeLocale(String locale) {
    translations.remove(locale);
  }

  /// Remove a specific field translation from a locale
  void removeTranslation(String field, String locale) {
    translations[locale]?.remove(field);
  }

  /// Clear all translations
  void clearTranslations() {
    translations.clear();
  }

  /// Get translation count for a locale
  int getTranslationCount(String locale) {
    return translations[locale]?.length ?? 0;
  }

  /// Check if translations are complete for a locale
  ///
  /// Returns true if all translatable fields have translations.
  bool isTranslationComplete(String locale) {
    if (translatableFields.isEmpty) return true;
    final localeTranslations = translations[locale] ?? {};
    return translatableFields
        .every((field) => localeTranslations.containsKey(field));
  }

  /// Get missing translation fields for a locale
  ///
  /// Returns list of fields that don't have translations.
  List<String> getMissingTranslations(String locale) {
    if (translatableFields.isEmpty) return [];
    final localeTranslations = translations[locale] ?? {};
    return translatableFields
        .where((field) => !localeTranslations.containsKey(field))
        .toList();
  }
}

import '../contracts/config/config_contract.dart';
import '../contracts/container/container_interface.dart';
import '../contracts/env/env_interface.dart';
import '../contracts/events/event_system_interface.dart';
import '../contracts/provider/service_provider.dart';
import '../core/cache/cache_manager.dart';
import '../core/container/container_provider.dart';
import '../core/database/database.dart';
import '../core/database/migration/migrator.dart';
import '../core/database/migration/seeder.dart';
import '../core/http/middleware/middleware_pipeline.dart';
import '../core/lang/lang.dart';
import '../core/logging/logger.dart';
import '../core/queue/queue_manager.dart';
import '../core/scheduler/scheduler.dart';
import '../core/service_provider/service_provider_manager.dart';
import '../core/socket/socket_manager.dart';
import '../core/view/renderer.dart';
import '../modules/auth/core/auth_service_provider.dart';
import '../modules/auth/services/auth_manager.dart';
import '../support/providers/core_service_provider.dart';
import '../support/providers/database_service_provider.dart';
import '../support/providers/queue_service_provider.dart';

/// Central access point for all Khadem framework services and utilities.
class Khadem {
  Khadem._();

  // ========= 🔧 Container & Provider System =========

  static ContainerInterface? _customContainer;

  /// Returns the current IoC container (default or custom).
  static ContainerInterface get container =>
      _customContainer ?? ContainerProvider.instance;

  /// Returns the service provider manager.
  static final ServiceProviderManager _providerManager =
      ServiceProviderManager(container);

  static ServiceProviderManager get providers => _providerManager;

  // ========= ⚙️ Core Bootstrapping =========

  /// Registers core service providers (basic, queue, auth).
  static Future<void> registerCoreServices() async {
    register([
      CoreServiceProvider(),
      QueueServiceProvider(),
      AuthServiceProvider(),
    ]);
  }

  /// Lightweight boot (ideal for master isolate).
  static Future<void> boot() async {
    await providers.bootAll();
  }

  /// Register service providers.
  static void register(List<ServiceProvider> serviceProviders) {
    providers.registerAll(serviceProviders);
  }

  /// Inject external container (useful for testing).
  static Future<ContainerInterface> use(ContainerInterface container) async {
    _customContainer = container;
    return _customContainer!;
  }

  /// Register configurations from a registry map.
  static void loadConfigs(Map<String, Map<String, dynamic>> configs) {
    config.loadFromRegistry(configs);
  }

  /// Register and boot database-related services.
  static Future<void> registerDatabaseServices() async {
    final dbProvider = DatabaseServiceProvider();
    register([dbProvider]);
    await dbProvider.boot(container);
  }

  // ========= 🧠 Common Services =========

  static Logger get logger => container.resolve<Logger>();
  static CacheManager get cache => container.resolve<CacheManager>();
  static EnvInterface get env => container.resolve<EnvInterface>();
  static ConfigInterface get config => container.resolve<ConfigInterface>();

  static MiddlewarePipeline get middleware =>
      container.resolve<MiddlewarePipeline>();
  static DatabaseManager get db => container.resolve<DatabaseManager>();
  static Migrator get migrator => container.resolve<Migrator>();
  static SeederManager get seeder => container.resolve<SeederManager>();
  static QueueManager get queue => container.resolve<QueueManager>();
  static EventSystemInterface get eventBus =>
      container.resolve<EventSystemInterface>();
  static AuthManager get auth => container.resolve<AuthManager>();
  static SocketManager get socket => container.resolve<SocketManager>();

  // ========= 📅 Scheduler & View System =========

  /// Returns the scheduler engine for managing tasks.
  static SchedulerEngine get scheduler => SchedulerEngine();

  /// Returns the view renderer for template rendering.
  static ViewRenderer get view => ViewRenderer.instance;

  // ========= 🌐 Localization =========

  /// Sets the global locale for all translations.
  ///
  /// This affects all translation calls that don't specify a locale.
  /// Use this for application-wide locale changes.
  ///
  /// ```dart
  /// Khadem.setGlobalLocale('fr');
  /// ```
  static void setGlobalLocale(String locale) => Lang.setGlobalLocale(locale);

  /// Gets the current global locale.
  static String getGlobalLocale() => Lang.getGlobalLocale();

  /// Sets the fallback locale for missing translations.
  ///
  /// When a translation is not found in the current locale,
  /// this locale will be used as a fallback.
  ///
  /// ```dart
  /// Khadem.setFallbackLocale('en');
  /// ```
  static void setFallbackLocale(String locale) => Lang.setFallbackLocale(locale);

  /// Gets the current fallback locale.
  static String getFallbackLocale() => Lang.getFallbackLocale();

  /// Sets the locale for the current request.
  ///
  /// This is useful for per-request localization in web applications.
  /// The locale is stored in the request context.
  ///
  /// ```dart
  /// Khadem.setRequestLocale('es');
  /// ```
  static void setRequestLocale(String locale) => Lang.setRequestLocale(locale);

  /// Translates a key with optional parameters and namespace.
  ///
  /// Supports advanced parameter replacement using :param syntax.
  /// Falls back to global/request locale if none specified.
  ///
  /// ```dart
  /// String greeting = Khadem.translate('messages.greeting', parameters: {'name': 'Alice'});
  /// String namespaced = Khadem.translate('login', namespace: 'auth');
  /// ```
  static String translate(String key, {
    Map<String, dynamic>? parameters,
    String? locale,
    String? namespace,
  }) => Lang.t(key, parameters: parameters, locale: locale, namespace: namespace);

  /// Translates with pluralization based on count.
  ///
  /// Handles singular/plural forms based on the count value.
  /// Expects translation keys with | separator for plural forms.
  ///
  /// ```dart
  /// String apples = Khadem.translateChoice('apples', 3); // "3 apples"
  /// String item = Khadem.translateChoice('item', 1); // "1 item"
  /// ```
  static String translateChoice(String key, int count, {
    Map<String, dynamic>? parameters,
    String? locale,
    String? namespace,
  }) => Lang.choice(key, count, parameters: parameters, locale: locale, namespace: namespace);

  /// Translates a field label.
  ///
  /// Convenience method for form field labels.
  /// Automatically prefixes with 'fields.' namespace.
  ///
  /// ```dart
  /// String emailLabel = Khadem.translateField('email'); // Looks for 'fields.email'
  /// ```
  static String translateField(String field, {String? locale, String? namespace}) =>
      Lang.getField(field, locale: locale, namespace: namespace);

  /// Checks if a translation key exists.
  ///
  /// Useful for conditional translations or debugging.
  ///
  /// ```dart
  /// if (Khadem.hasTranslation('messages.welcome')) {
  ///   // Translation exists
  /// }
  /// ```
  static bool hasTranslation(String key, {String? locale, String? namespace}) =>
      Lang.has(key, locale: locale, namespace: namespace);

  /// Gets the raw translation value without parameter replacement.
  ///
  /// Returns the translation string as-is, or null if not found.
  ///
  /// ```dart
  /// String? raw = Khadem.getTranslation('messages.greeting');
  /// ```
  static String? getTranslation(String key, {String? locale, String? namespace}) =>
      Lang.get(key, locale: locale, namespace: namespace);

  /// Loads translations for a specific namespace.
  ///
  /// Useful for loading package-specific or module-specific translations.
  ///
  /// ```dart
  /// Khadem.loadTranslationNamespace('package:auth', 'en', {
  ///   'login': 'Sign In',
  ///   'logout': 'Sign Out'
  /// });
  /// ```
  static void loadTranslationNamespace(String namespace, String locale, Map<String, String> translations) =>
      Lang.loadNamespace(namespace, locale, translations);

  /// Clears the translation cache.
  ///
  /// Forces reloading of translations on next access.
  /// Useful during development or after updating translation files.
  ///
  /// ```dart
  /// Khadem.clearTranslationCache();
  /// ```
  static void clearTranslationCache() => Lang.clearCache();

  /// Gets all available locales from the translation files.
  ///
  /// Returns a list of locale codes found in the lang directory.
  ///
  /// ```dart
  /// List<String> locales = Khadem.getAvailableLocales(); // ['en', 'fr', 'es']
  /// ```
  static List<String> getAvailableLocales() => Lang.getAvailableLocales();

  /// Adds a custom parameter replacer function.
  ///
  /// Allows extending parameter replacement logic for complex formatting.
  ///
  /// ```dart
  /// Khadem.addTranslationParameterReplacer((key, value, params) {
  ///   if (key == 'currency' && value is num) {
  ///     return '\$${value.toStringAsFixed(2)}';
  ///   }
  ///   return ':$key';
  /// });
  /// ```
  static void addTranslationParameterReplacer(String Function(String key, dynamic value, Map<String, dynamic> parameters) replacer) =>
      Lang.addParameterReplacer(replacer);

  // ========= 🛠️ Utilities =========

  /// Framework version.
  static String get version => '1.0.0';

  /// Checks if the framework is fully booted.
  static bool get isBooted => providers.isBooted;

  /// Checks if the application is running in production mode.
  static bool get isProduction => env.getOrDefault('APP_ENV', 'production') == 'production';

  /// Checks if the application is running in development mode.
  static bool get isDevelopment => env.getOrDefault('APP_ENV', 'production') == 'development';

  /// Shuts down all services (e.g., stops schedulers, closes DB connections).
  static Future<void> shutdown() async {
    scheduler.stopAll();
    await db.close();
    // Add more cleanup as needed
  }
}
 
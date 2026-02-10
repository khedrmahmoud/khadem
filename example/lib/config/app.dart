import 'package:khadem/khadem.dart' show Khadem;

// Import individual config files
import 'auth.dart';
import 'cache.dart';
import 'mail.dart';
import 'queue.dart';
import 'scheduler.dart';
import 'storage.dart';

class AppConfig {
  static final env = Khadem.env;

  /// Default configuration
  static Map<String, Map<String, dynamic>> get configs => {
        /// Application configuration
        'app': {
          'url': env.getOrDefault('APP_URL', 'http://localhost:9000'),
          'env': env.getOrDefault('APP_ENV', 'production'),
          'locale': env.getOrDefault('APP_LOCALE', 'en'),
          'name': env.getOrDefault('APP_NAME', 'Khadem App'),
          // Prefer APP_PORT (matches generated .env.example), fallback to HTTP_PORT.
          'http_port': env.getInt(
            'APP_PORT',
            defaultValue: env.getInt('HTTP_PORT', defaultValue: 9000),
          ),
          'socket_port': env.getInt('SOCKET_PORT', defaultValue: 8080),
        },

        /// Database configuration
        /// See: lib/config/database.dart
        // 'database': DatabaseConfig.config,

        /// Cache configuration
        /// See: lib/config/cache.dart
        'cache': CacheConfig.config,

        /// Queue configuration
        /// See: lib/config/queue.dart
        'queue': QueueConfig.config,

        /// Auth configuration
        /// See: lib/config/auth.dart
        'auth': AuthConfig.config,

        /// Storage configuration
        /// See: lib/config/storage.dart
        'storage': StorageConfig.config,

        /// Scheduler configuration
        /// See: lib/config/scheduler.dart
        'scheduler': SchedulerConfig.config,

        /// Mail configuration
        /// See: lib/config/mail.dart
        'mail': MailConfig.config,
      };
}

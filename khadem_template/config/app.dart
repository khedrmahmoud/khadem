import 'package:khadem/khadem_dart.dart' show Khadem;

class AppConfig {
  static final env = Khadem.env;

  /// 🌱 Default configuration
  static Map<String, Map<String, dynamic>> get configs => {
        /// Database configuration
        'database': {
          'driver': env.getOrDefault('DB_CONNECTION', 'mysql'),
          'host': env.getOrDefault('DB_HOST', 'localhost'),
          'port': env.getInt('DB_PORT'),
          'database': env.get('DB_DATABASE'),
          'username': env.get('DB_USERNAME'),
          // 'password': env.get('DB_PASSWORD'),
          'run_migrations': true,
          'run_seeders': false,
        },

        /// Cache configuration
        'cache': {
          'default': 'hybrid',
          'drivers': {
            'file': {'driver': 'file', 'path': 'storage/cache'},
            'memory': {'driver': 'memory'},
            'hybrid': {'driver': 'hybrid', 'path': 'storage/cache'},
            'redis': {'driver': 'redis', 'host': '127.0.0.1', 'port': 6379},
          },
        },

        /// Queue configuration
        'queue': {
          'driver': 'file', // sync, redis, file, database, memory
          // "max_jobs": 5,
          // "delay": 5,
          // "timeout": 10,
          "run_in_background": true,
          "auto_start": true,
        },

        /// Auth configuration
        'auth': {
          'default': 'users',
          'guards': {
            'users': {'driver': 'token', 'provider': 'users'},
            'admins': {'driver': 'token', 'provider': 'admins'},
          },
          'providers': {
            'users': {
              'table': 'users',
              'primary_key': 'id',
              'fields': ['email'],
            },
            'admins': {
              'table': 'admins',
              'primary_key': 'id',
              'fields': ['email'],
            },
          },
        },

        /// Storage configuration
        'storage': {
          'default': 'local',
          'drivers': {
            'local': {'driver': 'local', 'root': 'storage'},
            'public': {
              'driver': 'local',
              'root': './storage/public',
            },
            's3': {
              'driver': 's3',
              'key': 'your-key',
              'secret': 'your-secret',
              'region': 'your-region',
              'bucket': 'your-bucket',
            },
          },
        },

        /// Scheduler configuration
        "scheduler": {
          "tasks": [
            {
              "name": "ping_from_config",
              "job": "ping",
              "interval": 600,
              "retryOnFail": true,
            },
            {
              "name": "cache_clean_config",
              "job": "ttl_cleaner",
              "interval": 600,
              "retryOnFail": false,
              'cachePath': 'storage/cache',
            }
          ],
        },

        /// CORS configuration
        "cors": {
          "allowed_origins": [
            "http://localhost:8080",
            //"https://your-frontend.com"
          ],
          "allowed_methods": "GET, POST, PUT, DELETE, OPTIONS",
          "allowed_headers":
              "Accept, Content-Type, Authorization, X-Requested-With",
        },
      };
}

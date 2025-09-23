import 'package:khadem/khadem.dart' show Khadem;

class AppConfig {
  static final env = Khadem.env;

  /// 🌱 Default configuration
  static Map<String, Map<String, dynamic>> get configs => {
        /// Database configuration
        // 'database': {
        //   'driver': env.getOrDefault('DB_CONNECTION', 'mysql'),
        //   'host': env.getOrDefault('DB_HOST', 'localhost'),
        //   'port': env.getInt('DB_PORT'),
        //   'database': env.get('DB_NAME'),
        //   'username': env.get('DB_USER'),
        //   'password': env.get('DB_PASSWORD'),
        //   'run_migrations': true,
        //   'run_seeders': false,
        // },

        /// Cache configuration
        'cache': {
          'default': 'memory',
          'drivers': {
            'file': {'driver': 'file', 'path': 'storage/cache'},
            'memory': {'driver': 'memory'},
            'redis': {
              'driver': 'redis',
              'host': env.getOrDefault('REDIS_HOST', '127.0.0.1'),
              'port': env.getInt('REDIS_PORT', defaultValue: 6379),
              'password': env.get('REDIS_PASSWORD'),
            },
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
          'drivers': {
            'file': {'driver': 'file', 'path': 'storage/queue'},
            'memory': {'driver': 'memory'},
            'sync': {'driver': 'sync'},
            'redis': {
              'driver': 'redis',
              'host': env.getOrDefault('REDIS_HOST', '127.0.0.1'),
              'port': env.getInt('REDIS_PORT', defaultValue: 6379),
              'password': env.get('REDIS_PASSWORD'),
            },
          },
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
              'root': 'public/assets',
            },
          },
        },

        /// Scheduler configuration
        "scheduler": {
          "tasks": [
            // {
            //   "name": "ping_from_config",
            //   "job": "ping",
            //   "interval": 600,
            //   "retryOnFail": true,
            // },
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

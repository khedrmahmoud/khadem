import 'package:khadem/khadem.dart' show Khadem;

class AppConfig {
  static final env = Khadem.env;

  /// 🌱 Default configuration
  static Map<String, Map<String, dynamic>> get configs => {
        "app": {
          "url": env.getOrDefault('APP_URL', 'http://localhost:9000'),
          "asset_url": env.get('ASSET_URL'),
          "name": env.getOrDefault('APP_NAME', 'Khadem Video Streaming'),
          "port": env.getInt('APP_PORT', defaultValue: 3000),
        },

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
          'defaults': {
            'guard': 'api',
          },
          'guards': {
            'web': {
              'driver': 'token',
            },
            'api': {
              'driver': 'jwt',
            },
          },
          'providers': {
            'users': {
              'model': 'User',
              'table': 'users',
              'primary_key': 'id',
              'fields': ['email'],
            },
            'admins': {
              'model': 'Admin',
              'table': 'admins',
              'primary_key': 'id',
              'fields': ['email'],
            },
          },
        },

        /// Storage configuration
        'storage': {
          'default': 'local',
          'disks': {
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

        /// Mail configuration
        'mail': {
          'default': env.getOrDefault('MAIL_DRIVER', 'log'),
          'from': {
            'address':
                env.getOrDefault('MAIL_FROM_ADDRESS', 'noreply@example.com'),
            'name': env.getOrDefault('MAIL_FROM_NAME', 'Khadem Framework'),
          },
          'smtp': {
            'host': env.getOrDefault('SMTP_HOST', 'smtp.mailtrap.io'),
            'port': env.getInt('SMTP_PORT', defaultValue: 2525),
            'username': env.get('SMTP_USERNAME'),
            'password': env.get('SMTP_PASSWORD'),
            'encryption': env.getOrDefault('SMTP_ENCRYPTION', 'tls'),
            'timeout': env.getInt('SMTP_TIMEOUT', defaultValue: 30),
          },
          'mailgun': {
            'domain': env.get('MAILGUN_DOMAIN'),
            'apiKey': env.get('MAILGUN_API_KEY'),
            'endpoint':
                env.getOrDefault('MAILGUN_ENDPOINT', 'https://api.mailgun.net'),
          },
          'ses': {
            'accessKeyId': env.get('SES_ACCESS_KEY_ID'),
            'secretAccessKey': env.get('SES_SECRET_ACCESS_KEY'),
            'region': env.getOrDefault('SES_REGION', 'us-east-1'),
          },
          'postmark': {
            'serverToken': env.get('POSTMARK_SERVER_TOKEN'),
            'messageStream':
                env.getOrDefault('POSTMARK_MESSAGE_STREAM', 'outbound'),
          },
        },
      };
}

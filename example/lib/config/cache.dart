import 'package:khadem/khadem.dart' show Khadem;

class CacheConfig {
  static final env = Khadem.env;

  static Map<String, dynamic> get config => {
        'default': 'memory',
        'drivers': {
          'file': {
            'driver': 'file',
            'path': 'storage/cache',
          },
          'memory': {
            'driver': 'memory',
          },
          'redis': {
            'driver': 'redis',
            'host': env.getOrDefault('REDIS_HOST', '127.0.0.1'),
            'port': env.getInt('REDIS_PORT', defaultValue: 6379),
            'password': env.get('REDIS_PASSWORD'),
          },
        },
      };
}

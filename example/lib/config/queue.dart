import 'package:khadem/khadem.dart' show Khadem;

class QueueConfig {
  static final env = Khadem.env;

  static Map<String, dynamic> get config => {
        'default': 'memory', // Default driver to use
        'drivers': {
          'memory': {
            'driver': 'memory',
            'track_metrics': true,
            'use_dlq': true,
            'max_retries': 3,
          },
          'file': {
            'driver': 'file',
            'path': './storage/queue',
            'track_metrics': true,
            'use_dlq': true,
          },
          'sync': {
            'driver': 'sync',
          },
          'redis': {
            'driver': 'redis',
            'host': env.getOrDefault('REDIS_HOST', '127.0.0.1'),
            'port': env.getInt('REDIS_PORT', defaultValue: 6379),
            'password': env.get('REDIS_PASSWORD'),
            'queue_name': 'default',
            'track_metrics': true,
            'use_dlq': true,
          },
        },
      };
}

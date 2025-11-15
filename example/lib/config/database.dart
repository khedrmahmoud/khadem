import 'package:khadem/khadem.dart' show Khadem;

class DatabaseConfig {
  static final env = Khadem.env;

  static Map<String, dynamic> get config => {
        'driver': env.getOrDefault('DB_CONNECTION', 'mysql'),
        'host': env.getOrDefault('DB_HOST', 'localhost'),
        'port': env.getInt('DB_PORT'),
        'database': env.get('DB_NAME'),
        'username': env.get('DB_USER'),
        'password': env.get('DB_PASSWORD'),
        'run_migrations': true,
        'run_seeders': false,
      };
}

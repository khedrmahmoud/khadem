import 'package:khadem/khadem.dart' show Khadem;

class AuthConfig {
  static final env = Khadem.env;

  static Map<String, dynamic> get config => {
        'defaults': {
          'guard': 'api',
          'provider': 'users',
        },
        'guards': {
          'web': {
            'driver': 'token',
            'provider': 'users',
          },
          'api': {
            'driver': 'jwt',
            'provider': 'users',
          },
        },
        'drivers': {
          'jwt': {
            'jwt_secret': env.getOrDefault('JWT_SECRET', 'default-secret-key'),
            'access_token_expiry': 3600,
            'refresh_token_expiry': 604800,
          },
          'token': {
            'access_token_expiry': 3600,
            'refresh_token_expiry': 604800,
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
      };
}

import '../../../application/khadem.dart';
import '../core/auth_driver.dart';
import '../exceptions/auth_exception.dart';
import 'jwt_auth_service.dart';
import 'token_auth_service.dart';

class AuthManager {
  late final String _guard;
  late final AuthDriver _driver;

  AuthManager({String? guard}) {
    final config = Khadem.config.section('auth');
    if (config != null) {
      _guard = guard ?? config['default'] as String;

      final guardConf = config['guards'][_guard];

      if (guardConf['driver'] == 'jwt') {
        _driver = JWTAuthService(providerKey: guardConf['provider'] as String);
      } else {
        _driver = TokenAuthService(providerKey: guardConf['provider'] as String);
      }
    } else {
      throw AuthException('Auth config not found');
    }
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) =>
      _driver.attemptLogin(credentials);
  Future<Map<String, dynamic>> verify(String token) =>
      _driver.verifyToken(token);
  Future<void> logout(String token) => _driver.logout(token);
}

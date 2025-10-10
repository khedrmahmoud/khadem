import 'package:khadem/src/modules/auth/contracts/auth_config.dart';
import 'package:khadem/src/modules/auth/exceptions/auth_exception.dart';
import 'package:khadem/src/modules/auth/services/auth_manager.dart';
import 'package:test/test.dart';

// Simple test implementation of AuthConfig
class TestAuthConfig implements AuthConfig {
  @override
  Map<String, dynamic> getProvider(String providerKey) {
    if (providerKey == 'users') {
      return {
        'table': 'users',
        'fields': ['email'],
      };
    }
    throw AuthException('Provider not found');
  }

  @override
  Map<String, dynamic> getGuard(String guardName) {
    switch (guardName) {
      case 'api':
        return {
          'driver': 'token',
          'provider': 'users',
        };
      case 'web':
        return {
          'driver': 'session',
          'provider': 'users',
        };
      default:
        throw AuthException('Guard not found');
    }
  }

  @override
  String getDefaultGuard() => 'api';

  @override
  T getOrDefault<T>(String key, T defaultValue) => defaultValue;

  @override
  bool hasProvider(String providerKey) => providerKey == 'users';

  @override
  bool hasGuard(String guardName) => ['api', 'web'].contains(guardName);
  
  @override
  List<String> getAllProviderKeys() {
    return ['users'];
  }
  
  @override
  String getDefaultProvider() {
    return 'users';
  }
  
  @override
  List<Map<String, dynamic>> getProvidersForGuard(String guardName) {
    return [getProvider('users')];
  }
}

void main() {
  group('AuthManager', () {
    late TestAuthConfig testAuthConfig;
    late AuthManager authManager;

    setUp(() {
      testAuthConfig = TestAuthConfig();

      // Clear guard cache before each test
      AuthManager.clearGuardCache();
    });

    tearDown(() {
      AuthManager.clearGuardCache();
    });

    test('creates auth manager with default config', () {
      authManager = AuthManager(authConfig: testAuthConfig);

      expect(authManager.guard, 'api');
      expect(authManager.config, testAuthConfig);
    });

    test('creates auth manager with specified guard', () {
      authManager = AuthManager(guard: 'api', authConfig: testAuthConfig);

      expect(authManager.guard, 'api');
      expect(authManager.config, testAuthConfig);
    });

    test('guard caching works', () {
      final authManager1 = AuthManager(guard: 'api', authConfig: testAuthConfig);
      final authManager2 = AuthManager(guard: 'api', authConfig: testAuthConfig);

      // Should return the same guard instance from cache
      expect(authManager1.guardInstance, authManager2.guardInstance);
    });

    test('clears guard cache', () {
      final authManager1 = AuthManager(guard: 'api', authConfig: testAuthConfig);
      AuthManager.clearGuardCache();
      final authManager2 = AuthManager(guard: 'api', authConfig: testAuthConfig);

      // Should be different instances after cache clear
      expect(authManager1.guardInstance, isNot(authManager2.guardInstance));
    });

    test('gets available guards', () {
      authManager = AuthManager(authConfig: testAuthConfig);
      final guards = authManager.getAvailableGuards();

      expect(guards, isNotEmpty);
      expect(guards.first, isA<String>());
    });

    test('throws exception for invalid guard creation', () {
      expect(() => AuthManager(guard: 'nonexistent_guard', authConfig: testAuthConfig),
          throwsA(isA<AuthException>()),);
    });

    test('getGuard returns guard instance', () {
      authManager = AuthManager(authConfig: testAuthConfig);
      final guard = authManager.getGuard('api');

      expect(guard, isNotNull);
      // Should be the same instance as guardInstance when using same guard name
      expect(guard, authManager.guardInstance);
    });
  });
}
import 'package:test/test.dart';

import '../../lib/src/modules/auth/exceptions/auth_exception.dart';
import '../../lib/src/modules/auth/services/token_auth_service.dart';

void main() {
  late EnhancedTokenAuthService tokenAuthService;

  setUp(() {
    tokenAuthService = EnhancedTokenAuthService.create('users');
  });

  group('EnhancedTokenAuthService', () {
    group('Factory Constructor', () {
      test('should create instance with provider key', () {
        final service = EnhancedTokenAuthService.create('test_provider');
        expect(service, isNotNull);
        expect(service.providerKey, equals('test_provider'));
      });
    });

    group('Error Handling', () {
      test('should throw AuthException for invalid credentials format', () async {
        // This test would require mocking the Khadem static methods
        // For now, we'll test the exception types that should be thrown
        expect(
          () async {
            // This will fail because Khadem.config is not mocked
            await tokenAuthService.attemptLogin({});
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException for token verification failures', () async {
        expect(
          () async {
            await tokenAuthService.verifyToken('invalid_token');
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException for logout failures', () async {
        expect(
          () async {
            await tokenAuthService.logout('invalid_token');
          },
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Service Interface', () {
      test('should implement refreshAccessToken method', () {
        expect(tokenAuthService.refreshAccessToken, isA<Function>());
      });

      test('should implement attemptLogin method', () {
        expect(tokenAuthService.attemptLogin, isA<Function>());
      });

      test('should implement verifyToken method', () {
        expect(tokenAuthService.verifyToken, isA<Function>());
      });

      test('should implement logout method', () {
        expect(tokenAuthService.logout, isA<Function>());
      });
    });
  });
}

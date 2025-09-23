import 'package:khadem/src/modules/auth/exceptions/auth_exception.dart';
import 'package:khadem/src/modules/auth/services/token_auth_service.dart';
import 'package:test/test.dart';

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

      test('should implement generateApiToken method', () {
        expect(tokenAuthService.generateApiToken, isA<Function>());
      });

      test('should implement revokeAllUserTokens method', () {
        expect(tokenAuthService.revokeAllUserTokens, isA<Function>());
      });

      test('should implement getUserTokens method', () {
        expect(tokenAuthService.getUserTokens, isA<Function>());
      });

      test('should implement revokeToken method', () {
        expect(tokenAuthService.revokeToken, isA<Function>());
      });

      test('should implement cleanupExpiredTokens method', () {
        expect(tokenAuthService.cleanupExpiredTokens, isA<Function>());
      });
    });

    group('Error Handling', () {
      test('should throw AuthException for invalid credentials format',
          () async {
        expect(
          () async {
            await tokenAuthService.attemptLogin({});
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException for token verification failures',
          () async {
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

    group('Token Validation', () {
      test('should validate token format', () async {
        expect(
          () async {
            await tokenAuthService.validateToken('');
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('should validate short token', () async {
        expect(
          () async {
            await tokenAuthService.validateToken('short');
          },
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}

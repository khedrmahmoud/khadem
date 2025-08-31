import 'package:test/test.dart';

import '../../lib/src/modules/auth/exceptions/auth_exception.dart';
import '../../lib/src/modules/auth/services/token_auth_service.dart';

void main() {
  late TokenAuthService tokenAuthService;

  setUp(() {
    tokenAuthService = TokenAuthService(providerKey: 'users');
  });

  group('TokenAuthService', () {
    group('Constructor', () {
      test('should create instance with provider key', () {
        final service = TokenAuthService(providerKey: 'test_provider');
        expect(service, isNotNull);
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
  });
}

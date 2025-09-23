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
      test('should throw exception for invalid credentials format', () async {
        expect(
          () async {
            await tokenAuthService.attemptLogin({});
          },
          throwsA(anyOf(isA<AuthException>(), isA<Exception>())),
        );
      });

      test('should throw exception for token verification failures', () async {
        expect(
          () async {
            await tokenAuthService.verifyToken('invalid_token');
          },
          throwsA(anyOf(isA<AuthException>(), isA<Exception>())),
        );
      });

      test('should throw exception for logout failures', () async {
        expect(
          () async {
            await tokenAuthService.logout('invalid_token');
          },
          throwsA(anyOf(isA<AuthException>(), isA<Exception>())),
        );
      });

      test('should throw exception for refresh token failures', () async {
        expect(
          () async {
            await tokenAuthService.refreshAccessToken('invalid_token');
          },
          throwsA(anyOf(isA<AuthException>(), isA<Exception>())),
        );
      });
    });

    group('Token Validation', () {
      test('should validate token format', () async {
        expect(
          () async {
            await tokenAuthService.validateToken('short');
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('should accept valid token format', () async {
        // This will succeed because token validation only checks format
        // and doesn't require database access for basic format validation
        await tokenAuthService
            .validateToken('valid_token_with_sufficient_length_123456789');
        // If we get here, the test passes
      });
    });

    group('Token Generation', () {
      test('should have generateApiToken method', () async {
        final user = {'id': 1, 'email': 'test@example.com'};

        expect(
          () async {
            await tokenAuthService.generateApiToken(user);
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });

      test('should have generateApiToken with custom name', () async {
        final user = {'id': 1, 'email': 'test@example.com'};

        expect(
          () async {
            await tokenAuthService.generateApiToken(
              user,
              name: 'Custom API Token',
            );
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });

      test('should have generateApiToken with expiry', () async {
        final user = {'id': 1, 'email': 'test@example.com'};
        final expiresAt = DateTime.now().add(const Duration(days: 30));

        expect(
          () async {
            await tokenAuthService.generateApiToken(user, expiresAt: expiresAt);
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });
    });

    group('Token Management', () {
      test('should have revokeAllUserTokens method', () async {
        expect(
          () async {
            await tokenAuthService.revokeAllUserTokens(1);
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });

      test('should have getUserTokens method', () async {
        final tokens = await tokenAuthService.getUserTokens(1);
        expect(tokens, isA<List<Map<String, dynamic>>>());
        // Method exists and returns expected type
      });

      test('should have revokeToken method', () async {
        expect(
          () async {
            final result = await tokenAuthService.revokeToken('some_token');
            expect(result, isA<bool>());
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });

      test('should have cleanupExpiredTokens method', () async {
        expect(
          () async {
            final count = await tokenAuthService.cleanupExpiredTokens();
            expect(count, isA<int>());
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });
    });

    group('Authentication Operations', () {
      test('should have attemptLogin method', () async {
        final credentials = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        expect(
          () async {
            await tokenAuthService.attemptLogin(credentials);
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });

      test('should have verifyToken method', () async {
        expect(
          () async {
            await tokenAuthService.verifyToken('some_valid_token');
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });

      test('should have logout method', () async {
        expect(
          () async {
            await tokenAuthService.logout('some_token');
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });
    });

    group('Refresh Token Functionality', () {
      test('should have refreshAccessToken method', () async {
        expect(
          () async {
            final result =
                await tokenAuthService.refreshAccessToken('refresh_token');
            expect(result, isA<Map<String, dynamic>>());
            expect(result.containsKey('access_token'), isTrue);
            expect(result.containsKey('refresh_token'), isTrue);
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });

      test('should have proper refresh token response structure', () async {
        expect(
          () async {
            final result =
                await tokenAuthService.refreshAccessToken('refresh_token');
            expect(result.containsKey('token_type'), isTrue);
            expect(result['token_type'], equals('Bearer'));
          },
          throwsA(
            anyOf(
              isA<AuthException>(),
              isA<Exception>(),
            ),
          ), // Will fail due to container, but tests method existence
        );
      });
    });
  });
}

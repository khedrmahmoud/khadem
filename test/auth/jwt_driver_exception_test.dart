import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:khadem/src/modules/auth/contracts/auth_config.dart';
import 'package:khadem/src/modules/auth/contracts/token_service.dart';
import 'package:khadem/src/modules/auth/drivers/jwt_driver.dart';
import 'package:khadem/src/modules/auth/exceptions/auth_exception.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mocks/jwt_driver_exception_test.mocks.dart';

@GenerateMocks([AuthConfig, TokenService])
void main() {
  group('JWTDriver Exceptions', () {
    late JWTDriver driver;
    late MockAuthConfig mockConfig;
    late MockTokenService mockTokenService;
    const secret = 'test-secret-key-must-be-long-enough';

    setUp(() {
      mockConfig = MockAuthConfig();
      mockTokenService = MockTokenService();

      // Mock config provider
      when(mockConfig.getProvider(any)).thenReturn({
        'jwt_secret': secret,
        'table': 'users',
        'primary_key': 'id',
      });

      driver = JWTDriver(
        secret: secret,
        config: mockConfig,
        providerKey: 'users',
        tokenService: mockTokenService,
      );
    });

    test('verifyToken throws AuthException(401) when token is expired',
        () async {
      // Create an expired token
      final jwt = JWT(
        {'sub': 1},
        issuer: 'khadem',
      );
      // Sign with past expiration
      final token = jwt.sign(
        SecretKey(secret),
        expiresIn: const Duration(seconds: -1),
      );

      when(mockTokenService.isTokenBlacklisted(any))
          .thenAnswer((_) async => false);

      expect(
        () => driver.verifyToken(token),
        throwsA(isA<AuthException>()
            .having(
              (e) => e.statusCode,
              'statusCode',
              401,
            )
            .having(
              (e) => e.message,
              'message',
              contains('expired'),
            ),),
      );
    });

    test('verifyToken throws AuthException(401) when signature is invalid',
        () async {
      // Create a token signed with different secret
      final jwt = JWT({'sub': 1});
      final token = jwt.sign(SecretKey('wrong-secret'));

      when(mockTokenService.isTokenBlacklisted(any))
          .thenAnswer((_) async => false);

      expect(
        () => driver.verifyToken(token),
        throwsA(isA<AuthException>()
            .having(
              (e) => e.statusCode,
              'statusCode',
              401,
            )
            .having(
              (e) => e.message,
              'message',
              contains('Invalid token'),
            ),),
      );
    });

    test('verifyToken throws AuthException(401) when token is malformed',
        () async {
      when(mockTokenService.isTokenBlacklisted(any))
          .thenAnswer((_) async => false);

      expect(
        () => driver.verifyToken('malformed.token'),
        throwsA(isA<AuthException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        ),),
      );
    });
  });
}

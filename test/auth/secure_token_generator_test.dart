import 'package:khadem/src/modules/auth/services/secure_token_generator.dart';
import 'package:test/test.dart';

void main() {
  group('SecureTokenGenerator', () {
    late SecureTokenGenerator generator;

    setUp(() {
      generator = SecureTokenGenerator();
    });

    group('generateToken', () {
      test('should generate token with default length', () {
        final token = generator.generateToken();

        expect(token, isNotEmpty);
        expect(token.length, equals(64));
        expect(generator.isValidTokenFormat(token), isTrue);
      });

      test('should generate token with custom length', () {
        const customLength = 32;
        final token = generator.generateToken(length: customLength);

        expect(token.length, equals(customLength));
        expect(generator.isValidTokenFormat(token), isTrue);
      });

      test('should generate token with prefix', () {
        const prefix = 'test';
        final token = generator.generateToken(prefix: prefix);

        expect(token, startsWith('$prefix|'));
        expect(token.split('|'), hasLength(2));
        expect(token.split('|')[0], equals(prefix));
        expect(generator.isValidTokenFormat(token), isTrue);
      });

      test('should generate different tokens on each call', () {
        final token1 = generator.generateToken();
        final token2 = generator.generateToken();

        expect(token1, isNot(equals(token2)));
      });

      test('should generate token with length 1', () {
        final token = generator.generateToken(length: 1);

        expect(token.length, equals(1));
        expect(generator.isValidTokenFormat(token), isTrue);
      });
    });

    group('generateRefreshToken', () {
      test('should generate refresh token with default length', () {
        final token = generator.generateRefreshToken();

        expect(token, isNotEmpty);
        expect(token.length, equals(64));
        expect(generator.isValidTokenFormat(token), isTrue);
      });

      test('should generate refresh token with custom length', () {
        const customLength = 128;
        final token = generator.generateRefreshToken(length: customLength);

        expect(token.length, equals(customLength));
        expect(generator.isValidTokenFormat(token), isTrue);
      });

      test('should generate different refresh tokens', () {
        final token1 = generator.generateRefreshToken();
        final token2 = generator.generateRefreshToken();

        expect(token1, isNot(equals(token2)));
      });
    });

    group('isValidTokenFormat', () {
      test('should validate basic token format', () {
        const validTokens = [
          'abc123',
          'ABC_DEF-123',
          'token123',
          'a',
          'A_B-C_1-2-3',
        ];

        for (final token in validTokens) {
          expect(
            generator.isValidTokenFormat(token),
            isTrue,
            reason: 'Token "$token" should be valid',
          );
        }
      });

      test('should validate prefixed token format', () {
        const validTokens = [
          'prefix|token123',
          'auth|ABC_DEF-123',
          'bearer|token',
          'custom|value123',
        ];

        for (final token in validTokens) {
          expect(
            generator.isValidTokenFormat(token),
            isTrue,
            reason: 'Token "$token" should be valid',
          );
        }
      });

      test('should reject invalid token formats', () {
        const invalidTokens = [
          '',
          'token with spaces',
          'token@special',
          'token#hash',
          'token\$var',
          'token%percent',
          'token^caret',
          'token&ampersand',
          'token*star',
          'token(parenthesis)',
          'token[bracket]',
          'token{brace}',
          'token|',
          '|token',
          'prefix|',
          'prefix||token',
          'token|prefix|extra',
        ];

        for (final token in invalidTokens) {
          expect(
            generator.isValidTokenFormat(token),
            isFalse,
            reason: 'Token "$token" should be invalid',
          );
        }
      });

      test('should reject tokens with special characters', () {
        const invalidTokens = [
          'token@domain.com',
          'token#fragment',
          'token\$variable',
          'token%encoded',
          'token^power',
          'token&amp',
          'token*glob',
          'token(parent)',
          'token[arr]',
          'token{obj}',
          'token+plus',
          'token=equals',
          'token\\backslash',
          'token/slash',
          'token?query',
          'token<less',
          'token>greater',
          'token"quote',
          'token\'single',
          'token:colon',
          'token;semicolon',
          'token,comma',
          'token.dot',
          'token~tilde',
          'token`backtick',
        ];

        for (final token in invalidTokens) {
          expect(
            generator.isValidTokenFormat(token),
            isFalse,
            reason: 'Token "$token" should be invalid',
          );
        }
      });
    });

    group('generateNumericToken', () {
      test('should generate numeric token with default length', () {
        final token = generator.generateNumericToken();

        expect(token, isNotEmpty);
        expect(token.length, equals(6));
        expect(int.tryParse(token), isNotNull);
      });

      test('should generate numeric token with custom length', () {
        const customLength = 10;
        final token = generator.generateNumericToken(length: customLength);

        expect(token.length, equals(customLength));
        expect(int.tryParse(token), isNotNull);
      });

      test('should generate different numeric tokens', () {
        final token1 = generator.generateNumericToken();
        final token2 = generator.generateNumericToken();

        expect(token1, isNot(equals(token2)));
      });

      test('should generate numeric token with length 1', () {
        final token = generator.generateNumericToken(length: 1);

        expect(token.length, equals(1));
        expect(int.tryParse(token), isNotNull);
        expect(token, matches(r'^[0-9]$'));
      });
    });

    group('generateAlphanumericToken', () {
      test('should generate alphanumeric token with default length', () {
        final token = generator.generateAlphanumericToken();

        expect(token, isNotEmpty);
        expect(token.length, equals(32));
        expect(token, matches(r'^[A-Za-z0-9\-_]+$'));
      });

      test('should generate alphanumeric token with custom length', () {
        const customLength = 16;
        final token = generator.generateAlphanumericToken(length: customLength);

        expect(token.length, equals(customLength));
        expect(token, matches(r'^[A-Za-z0-9\-_]+$'));
      });

      test('should generate different alphanumeric tokens', () {
        final token1 = generator.generateAlphanumericToken();
        final token2 = generator.generateAlphanumericToken();

        expect(token1, isNot(equals(token2)));
      });

      test('should only contain valid characters', () {
        final token = generator.generateAlphanumericToken(length: 100);

        const validChars =
            'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
        for (final char in token.split('')) {
          expect(
            validChars.contains(char),
            isTrue,
            reason: 'Character "$char" should be in valid character set',
          );
        }
      });
    });

    group('generateUuidToken', () {
      test('should generate UUID-like token', () {
        final token = generator.generateUuidToken();

        expect(token, isNotEmpty);
        expect(token.length, equals(36)); // UUID format: 8-4-4-4-12
        expect(
            token,
            matches(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',),);
      });

      test('should generate different UUID tokens', () {
        final token1 = generator.generateUuidToken();
        final token2 = generator.generateUuidToken();

        expect(token1, isNot(equals(token2)));
      });

      test('should have correct UUID version and variant', () {
        final token = generator.generateUuidToken();

        // Version should be 4 (UUID v4)
        expect(token[14], equals('4'));

        // Variant should be RFC 4122 compliant (8, 9, a, or b in position 19)
        const validVariants = ['8', '9', 'a', 'b'];
        expect(validVariants.contains(token[19]), isTrue);
      });
    });
  });
}

import 'package:khadem/src/modules/auth/services/hash_password_verifier.dart';
import 'package:test/test.dart';

void main() {
  group('HashPasswordVerifier', () {
    late HashPasswordVerifier verifier;

    setUp(() {
      verifier = HashPasswordVerifier();
    });

    group('verify', () {
      test('should return true for matching password and hash', () async {
        const password = 'testPassword123';
        final hash = await verifier.hash(password);

        final result = await verifier.verify(password, hash);

        expect(result, isTrue);
      });

      test('should return false for non-matching password and hash', () async {
        const password = 'testPassword123';
        const wrongPassword = 'wrongPassword456';
        final hash = await verifier.hash(password);

        final result = await verifier.verify(wrongPassword, hash);

        expect(result, isFalse);
      });

      test('should return false for empty password', () async {
        const password = 'testPassword123';
        const emptyPassword = '';
        final hash = await verifier.hash(password);

        final result = await verifier.verify(emptyPassword, hash);

        expect(result, isFalse);
      });

      test('should return false for empty hash', () async {
        const password = 'testPassword123';
        const emptyHash = '';

        final result = await verifier.verify(password, emptyHash);

        expect(result, isFalse);
      });
    });

    group('hash', () {
      test('should return a non-empty hash', () async {
        const password = 'testPassword123';

        final result = await verifier.hash(password);

        expect(result, isNotEmpty);
        expect(result, isA<String>());
      });

      test('should return consistent hashes for same password', () async {
        const password = 'testPassword123';

        final hash1 = await verifier.hash(password);
        final hash2 = await verifier.hash(password);

        expect(hash1, equals(hash2));
      });

      test('should return different hashes for different passwords', () async {
        const password1 = 'testPassword123';
        const password2 = 'differentPassword456';

        final hash1 = await verifier.hash(password1);
        final hash2 = await verifier.hash(password2);

        expect(hash1, isNot(equals(hash2)));
      });

      test('should handle empty password', () async {
        const password = '';

        final result = await verifier.hash(password);

        expect(result, isNotEmpty);
      });

      test('should handle special characters', () async {
        const password = 'P@ssw0rd!#\$%^&*()';

        final result = await verifier.hash(password);

        expect(result, isNotEmpty);
      });
    });

    group('needsRehash', () {
      test('should return true for short hashes', () {
        const shortHash = 'short';

        final result = verifier.needsRehash(shortHash);

        expect(result, isTrue);
      });

      test('should return false for hashes longer than 60 characters', () {
        final longHash = 'a' * 61; // 61 characters

        final result = verifier.needsRehash(longHash);

        expect(result, isFalse);
      });

      test('should return false for hashes exactly 60 characters', () {
        final sixtyCharHash = 'a' * 60; // 60 characters

        final result = verifier.needsRehash(sixtyCharHash);

        expect(result, isFalse);
      });

      test('should return true for empty hash', () {
        const emptyHash = '';

        final result = verifier.needsRehash(emptyHash);

        expect(result, isTrue);
      });
    });

    group('validatePasswordStrength', () {
      test('should validate strong password', () {
        const password = 'StrongP@ssw0rd123!';

        final result = verifier.validatePasswordStrength(password);

        expect(result['isValid'], isTrue);
        expect(result['issues'], isEmpty);
        expect(result['strength'], greaterThan(80));
      });

      test('should reject password shorter than 8 characters', () {
        const password = 'Short1!';

        final result = verifier.validatePasswordStrength(password);

        expect(result['isValid'], isFalse);
        expect(result['issues'],
            contains('Password must be at least 8 characters long'),);
      });

      test('should reject password without uppercase letter', () {
        const password = 'lowercaseonly123!';

        final result = verifier.validatePasswordStrength(password);

        expect(result['isValid'], isFalse);
        expect(result['issues'],
            contains('Password must contain at least one uppercase letter'),);
      });

      test('should reject password without lowercase letter', () {
        const password = 'UPPERCASEONLY123!';

        final result = verifier.validatePasswordStrength(password);

        expect(result['isValid'], isFalse);
        expect(result['issues'],
            contains('Password must contain at least one lowercase letter'),);
      });

      test('should reject password without number', () {
        const password = 'NoNumbers!';

        final result = verifier.validatePasswordStrength(password);

        expect(result['isValid'], isFalse);
        expect(result['issues'],
            contains('Password must contain at least one number'),);
      });

      test('should reject password without special character', () {
        const password = 'NoSpecialChars123';

        final result = verifier.validatePasswordStrength(password);

        expect(result['isValid'], isFalse);
        expect(result['issues'],
            contains('Password must contain at least one special character'),);
      });

      test('should calculate strength correctly', () {
        const weakPassword = 'weak';
        const mediumPassword = 'Medium123';
        const strongPassword = 'VeryStrongP@ssw0rd123!';

        final weakResult = verifier.validatePasswordStrength(weakPassword);
        final mediumResult = verifier.validatePasswordStrength(mediumPassword);
        final strongResult = verifier.validatePasswordStrength(strongPassword);

        expect(weakResult['strength'], lessThan(mediumResult['strength']));
        expect(mediumResult['strength'], lessThan(strongResult['strength']));
      });

      test('should cap strength at 100', () {
        final veryLongPassword = 'A' * 50 + '1!a'; // Very long password

        final result = verifier.validatePasswordStrength(veryLongPassword);

        expect(result['strength'], equals(100));
      });
    });
  });
}

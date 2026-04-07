import 'package:khadem/src/contracts/validation/rule.dart';
import 'package:khadem/src/support/validation_rules/email.dart';
import 'package:test/test.dart';

void main() {
  late EmailRule rule;

  setUp(() {
    rule = EmailRule();
  });

  group('EmailRule', () {
    test('should return true for valid email addresses', () async {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+label@example.com',
        'firstname.lastname@domain.com',
      ];

      for (final email in validEmails) {
        final result = await rule.passes(
          ValidationContext(attribute: 'email', value: email, data: {}),
        );
        expect(result, isTrue, reason: 'Failed for email: $email');
      }
    });

    test('should return false for invalid email addresses', () async {
      final invalidEmails = [
        'invalid.email',
        '@domain.com',
        'user@',
        'user@domain',
        'user.domain.com',
        'user@domain.',
        '.user@example.com',
        'user..name@example.com',
        'user@-example.com',
        'user@example-.com',
        'user@example.123',
        'user@exam_ple.com',
      ];

      for (final email in invalidEmails) {
        final result = await rule.passes(
          ValidationContext(attribute: 'email', value: email, data: {}),
        );
        expect(result, isFalse, reason: 'Failed for email: $email');
      }
    });

    test('should return false when value is null', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'email', value: null, data: {}),
      );
      expect(result, isFalse);
    });

    test('should return false when value is not a string', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'email', value: 42, data: {}),
      );
      expect(result, isFalse);
    });

    test('should handle email addresses with special characters', () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'email',
          value: 'user.name+label@sub.domain-name.com',
          data: {},
        ),
      );
      expect(result, isTrue);
    });

    test('should reject excessively long email addresses', () async {
      final longLocal = 'a' * 65;
      final result = await rule.passes(
        ValidationContext(
          attribute: 'email',
          value: '$longLocal@example.com',
          data: {},
        ),
      );
      expect(result, isFalse);
    });
  });
}

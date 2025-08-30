import 'package:khadem/src/support/validation_rules/email.dart';
import 'package:test/test.dart';

void main() {
  late EmailRule rule;

  setUp(() {
    rule = EmailRule();
  });

  group('EmailRule', () {
    test('should return null for valid email addresses', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+label@example.com',
        'firstname.lastname@domain.com',
      ];

      for (final email in validEmails) {
        final result = rule.validate('email', email, null, data: {});
        expect(result, isNull, reason: 'Failed for email: $email');
      }
    });

    test('should return error message for invalid email addresses', () {
      final invalidEmails = [
        'invalid.email',
        '@domain.com',
        'user@',
        'user@domain',
        'user.domain.com',
        'user@domain.',
      ];

      for (final email in invalidEmails) {
        final result = rule.validate('email', email, null, data: {});
        expect(result, equals('email_validation'), reason: 'Failed for email: $email');
      }
    });

    test('should return error message when value is null', () {
      final result = rule.validate('email', null, null, data: {});
      expect(result, equals('email_validation'));
    });

    test('should return error message when value is not a string', () {
      final result = rule.validate('email', 42, null, data: {});
      expect(result, equals('email_validation'));
    });

    test('should handle email addresses with special characters', () {
      final result = rule.validate(
        'email',
        'user.name+label@sub.domain-name.com',
        null,
        data: {},
      );
      expect(result, isNull);
    });
  });
}
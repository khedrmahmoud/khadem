import 'package:khadem/src/core/validation/rule_registry.dart';
import 'package:khadem/src/core/validation/validator.dart';
import 'package:test/test.dart';

void main() {
  group('Enhanced Validation System', () {
    test('should validate with new string rules', () {
      final validator = Validator(
        {'username': 'john_doe123', 'name': 'John'},
        {'username': 'alpha_dash', 'name': 'alpha'},
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should validate with file rules', () {
      final validator = Validator(
        {'avatar': 'profile.jpg', 'document': 'resume.pdf'},
        {'avatar': 'image', 'document': 'mimes:pdf,doc,docx'},
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should validate with date rules', () {
      final validator = Validator(
        {'birth_date': '1990-01-01', 'event_date': '2024-12-25'},
        {'birth_date': 'date', 'event_date': 'date_format:Y-m-d'},
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should validate with network rules', () {
      final validator = Validator(
        {'website': 'https://example.com', 'ip_address': '192.168.1.1'},
        {'website': 'url', 'ip_address': 'ipv4'},
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should validate with array rules', () {
      final validator = Validator(
        {'tags': ['dart', 'flutter', 'mobile'], 'categories': [1, 2, 3]},
        {'tags': 'array|min_items:2|max_items:5', 'categories': 'distinct'},
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should validate with miscellaneous rules', () {
      final validator = Validator(
        {'id': '550e8400-e29b-41d4-a716-446655440000', 'phone': '+1234567890'},
        {'id': 'uuid', 'phone': 'phone'},
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should fail validation with invalid data', () {
      final validator = Validator(
        {'email': 'invalid-email', 'age': 'not-a-number'},
        {'email': 'email', 'age': 'int'},
      );

      expect(validator.passes(), isFalse);
      expect(validator.errors, contains('email'));
      expect(validator.errors, contains('age'));
    });

    test('should handle complex validation scenarios', () {
      final validator = Validator(
        {
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': '25',
          'website': 'https://johndoe.com',
          'tags': ['developer', 'dart'],
          'birth_date': '1999-01-01',
        },
        {
          'name': 'required|string|min:2',
          'email': 'required|email',
          'age': 'required|int|min:18',
          'website': 'url',
          'tags': 'array|min_items:1',
          'birth_date': 'date|before:today',
        },
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should demonstrate ValidationRuleRepository functionality', () {
      // Test that all rules are registered
      final registeredRules = ValidationRuleRepository.registeredRules;
      expect(registeredRules.length, greaterThan(10));

      // Test that specific rules are registered
      expect(registeredRules, contains('email'));
      expect(registeredRules, contains('string'));
      expect(registeredRules, contains('file'));
      expect(registeredRules, contains('date'));
      expect(registeredRules, contains('url'));
      expect(registeredRules, contains('array'));
      expect(registeredRules, contains('uuid'));

      // Test rule resolution
      final emailRule = ValidationRuleRepository.resolve('email');
      expect(emailRule, isNotNull);

      final stringRule = ValidationRuleRepository.resolve('string');
      expect(stringRule, isNotNull);

      final unknownRule = ValidationRuleRepository.resolve('unknown_rule');
      expect(unknownRule, isNull);
    });
  });
}

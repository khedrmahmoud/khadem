import 'package:test/test.dart';
import 'package:khadem/src/support/validation_rules/regex.dart';

void main() {
  late RegexRule rule;

  setUp(() {
    rule = RegexRule();
  });

  group('RegexRule', () {
    test('should return null when pattern matches the value', () {
      final result = rule.validate('field', 'abc123', r'^[a-z]+\d+$', data: {});
      expect(result, isNull);
    });

    test('should return null when arg is null', () {
      final result = rule.validate('field', 'any value', null, data: {});
      expect(result, isNull);
    });

    test('should return error message when pattern does not match the value', () {
      final result = rule.validate('field', 'abc', r'^\d+$', data: {});
      expect(result, equals('regex_validation'));
    });

    test('should return error message when value is not a string', () {
      final result = rule.validate('field', 42, r'^\d+$', data: {});
      expect(result, equals('regex_validation'));
    });

    test('should return error message when value is null', () {
      final result = rule.validate('field', null, r'^\w+$', data: {});
      expect(result, equals('regex_validation'));
    });

    test('should handle complex regex patterns', () {
      final result = rule.validate(
        'field',
        'test@example.com',
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        data: {},
      );
      expect(result, isNull);
    });
  });
}
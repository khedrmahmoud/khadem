import 'package:khadem/src/contracts/validation/rule.dart';
import 'package:khadem/src/support/validation_rules/regex.dart';
import 'package:test/test.dart';

void main() {
  late RegexRule rule;

  setUp(() {
    rule = RegexRule();
  });

  group('RegexRule', () {
    test('should return true when pattern matches the value', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: 'abc123',
        parameters: [r'^[a-z]+\d+$'],
        data: {},
      ),);
      expect(result, isTrue);
    });

    test('should return true when arg is empty', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: 'any value',
        parameters: [],
        data: {},
      ),);
      expect(result, isTrue);
    });

    test('should return false when pattern does not match the value',
        () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: 'abc',
        parameters: [r'^\d+$'],
        data: {},
      ),);
      expect(result, isFalse);
    });

    test('should return false when value is not a string', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: 42,
        parameters: [r'^\d+$'],
        data: {},
      ),);
      expect(result, isFalse);
    });

    test('should return false when value is null', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: null,
        parameters: [r'^\w+$'],
        data: {},
      ),);
      expect(result, isFalse);
    });

    test('should handle complex regex patterns', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: 'test@example.com',
        parameters: [r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'],
        data: {},
      ),);
      expect(result, isTrue);
    });
  });
}

import 'package:khadem/src/support/validation_rules/numeric.dart';
import 'package:test/test.dart';

void main() {
  late NumericRule rule;

  setUp(() {
    rule = NumericRule();
  });

  group('NumericRule', () {
    test('should return null when value is an integer', () {
      final result = rule.validate('field', 42, null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is a decimal number', () {
      final result = rule.validate('field', 42.5, null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is a string containing valid integer', () {
      final result = rule.validate('field', '42', null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is a string containing valid decimal', () {
      final result = rule.validate('field', '42.5', null, data: {});
      expect(result, isNull);
    });

    test('should return error message when value is non-numeric string', () {
      final result = rule.validate('field', 'not-a-number', null, data: {});
      expect(result, equals('numeric_validation'));
    });

    test('should return error message when value is null', () {
      final result = rule.validate('field', null, null, data: {});
      expect(result, equals('numeric_validation'));
    });

    test('should return error message when value is boolean', () {
      final result = rule.validate('field', true, null, data: {});
      expect(result, equals('numeric_validation'));
    });

    test('should return error message when value is empty string', () {
      final result = rule.validate('field', '', null, data: {});
      expect(result, equals('numeric_validation'));
    });
  });
}
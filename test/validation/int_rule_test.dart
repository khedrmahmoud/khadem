import 'package:test/test.dart';
import 'package:khadem/src/support/validation_rules/int_rule.dart';

void main() {
  late IntRule rule;

  setUp(() {
    rule = IntRule();
  });

  group('IntRule', () {
    test('should return null when value is an integer', () {
      final result = rule.validate('field', 42, null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is a string containing valid integer', () {
      final result = rule.validate('field', '42', null, data: {});
      expect(result, isNull);
    });

    test('should return error message when value is a string containing non-integer', () {
      final result = rule.validate('field', 'not-an-int', null, data: {});
      expect(result, equals('int_validation'));
    });

    test('should return error message when value is a decimal number', () {
      final result = rule.validate('field', 42.5, null, data: {});
      expect(result, equals('int_validation'));
    });

    test('should return error message when value is a string containing decimal', () {
      final result = rule.validate('field', '42.5', null, data: {});
      expect(result, equals('int_validation'));
    });

    test('should return error message when value is null', () {
      final result = rule.validate('field', null, null, data: {});
      expect(result, equals('int_validation'));
    });

    test('should return error message when value is boolean', () {
      final result = rule.validate('field', true, null, data: {});
      expect(result, equals('int_validation'));
    });
  });
}
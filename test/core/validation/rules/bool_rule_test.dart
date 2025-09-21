import 'package:khadem/src/support/validation_rules/bool_rule.dart';
import 'package:test/test.dart';

void main() {
  late BoolRule rule;

  setUp(() {
    rule = BoolRule();
  });

  group('BoolRule', () {
    test('should return null when value is a boolean true', () {
      final result = rule.validate('field', true, null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is a boolean false', () {
      final result = rule.validate('field', false, null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is string "true"', () {
      final result = rule.validate('field', 'true', null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is string "false"', () {
      final result = rule.validate('field', 'false', null, data: {});
      expect(result, isNull);
    });

    test('should return error message when value is non-boolean string', () {
      final result = rule.validate('field', 'not-a-bool', null, data: {});
      expect(result, equals('bool_validation'));
    });

    test('should return error message when value is null', () {
      final result = rule.validate('field', null, null, data: {});
      expect(result, equals('bool_validation'));
    });

    test('should return error message when value is number', () {
      final result = rule.validate('field', 1, null, data: {});
      expect(result, equals('bool_validation'));
    });
  });
}
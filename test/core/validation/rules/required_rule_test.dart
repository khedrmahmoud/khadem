import 'package:khadem/src/support/validation_rules/required.dart';
import 'package:test/test.dart';

void main() {
  late RequiredRule rule;

  setUp(() {
    rule = RequiredRule();
  });

  group('RequiredRule', () {
    test('should return error message when value is null', () {
      final result = rule.validate('field', null, null, data: {});
      expect(result, equals('required_validation'));
    });

    test('should return error message when value is empty string', () {
      final result = rule.validate('field', '', null, data: {});
      expect(result, equals('required_validation'));
    });

    test('should return error message when value is whitespace', () {
      final result = rule.validate('field', '   ', null, data: {});
      expect(result, equals('required_validation'));
    });

    test('should return null when value is non-empty string', () {
      final result = rule.validate('field', 'value', null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is number', () {
      final result = rule.validate('field', 42, null, data: {});
      expect(result, isNull);
    });

    test('should return null when value is boolean', () {
      final result = rule.validate('field', true, null, data: {});
      expect(result, isNull);
    });
  });
}
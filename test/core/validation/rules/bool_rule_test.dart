import 'package:khadem/src/contracts/validation/rule.dart';
import 'package:khadem/src/support/validation_rules/bool_rule.dart';
import 'package:test/test.dart';

void main() {
  late BoolRule rule;

  setUp(() {
    rule = BoolRule();
  });

  group('BoolRule', () {
    test('should return true when value is a boolean true', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'field', value: true, data: {}),
      );
      expect(result, isTrue);
    });

    test('should return true when value is a boolean false', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'field', value: false, data: {}),
      );
      expect(result, isTrue);
    });

    test('should return true when value is string "true"', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'field', value: 'true', data: {}),
      );
      expect(result, isTrue);
    });

    test('should return true when value is string "false"', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'field', value: 'false', data: {}),
      );
      expect(result, isTrue);
    });

    test('should return false when value is non-boolean string', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'field', value: 'not-a-bool', data: {}),
      );
      expect(result, isFalse);
    });

    test('should return false when value is null', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'field', value: null, data: {}),
      );
      expect(result, isFalse);
    });

    test('should return true when value is number 1 (if accepted)', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'field', value: 1, data: {}),
      );
      expect(result, isTrue);
    });

    test('should return true when value is number 0', () async {
      final result = await rule.passes(
        ValidationContext(attribute: 'field', value: 0, data: {}),
      );
      expect(result, isTrue);
    });
  });
}

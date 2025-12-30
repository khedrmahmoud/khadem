import 'package:khadem/src/contracts/validation/rule.dart';
import 'package:khadem/src/support/validation_rules/required.dart';
import 'package:test/test.dart';

void main() {
  late RequiredRule rule;

  setUp(() {
    rule = RequiredRule();
  });

  group('RequiredRule', () {
    test('should return false when value is null', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: null,
        data: {},
      ),);
      expect(result, isFalse);
    });

    test('should return false when value is empty string', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: '',
        data: {},
      ),);
      expect(result, isFalse);
    });

    test('should return false when value is whitespace', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: '   ',
        data: {},
      ),);
      expect(result, isFalse);
    });

    test('should return true when value is non-empty string', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: 'value',
        data: {},
      ),);
      expect(result, isTrue);
    });

    test('should return true when value is number', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: 42,
        data: {},
      ),);
      expect(result, isTrue);
    });

    test('should return true when value is boolean', () async {
      final result = await rule.passes(ValidationContext(
        attribute: 'field',
        value: true,
        data: {},
      ),);
      expect(result, isTrue);
    });
  });
}

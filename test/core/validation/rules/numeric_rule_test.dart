import 'package:khadem/src/contracts/validation/rule.dart';
import 'package:khadem/src/support/validation_rules/numeric.dart';
import 'package:test/test.dart';

void main() {
  late NumericRule rule;

  setUp(() {
    rule = NumericRule();
  });

  group('NumericRule', () {
    test('should return true when value is an integer', () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'field',
          value: 42,
          data: {},
        ),
      );
      expect(result, isTrue);
    });

    test('should return true when value is a decimal number', () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'field',
          value: 42.5,
          data: {},
        ),
      );
      expect(result, isTrue);
    });

    test('should return true when value is a string containing valid integer',
        () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'field',
          value: '42',
          data: {},
        ),
      );
      expect(result, isTrue);
    });

    test('should return true when value is a string containing valid decimal',
        () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'field',
          value: '42.5',
          data: {},
        ),
      );
      expect(result, isTrue);
    });

    test('should return false when value is non-numeric string', () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'field',
          value: 'not-a-number',
          data: {},
        ),
      );
      expect(result, isFalse);
    });

    test('should return false when value is null', () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'field',
          value: null,
          data: {},
        ),
      );
      expect(result, isFalse);
    });

    test('should return false when value is boolean', () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'field',
          value: true,
          data: {},
        ),
      );
      expect(result, isFalse);
    });

    test('should return false when value is empty string', () async {
      final result = await rule.passes(
        ValidationContext(
          attribute: 'field',
          value: '',
          data: {},
        ),
      );
      expect(result, isFalse);
    });
  });
}

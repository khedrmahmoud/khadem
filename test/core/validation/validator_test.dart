import 'package:khadem/src/core/validation/validator.dart';
import 'package:khadem/src/support/exceptions/validation_exception.dart';
import 'package:test/test.dart';

void main() {
  group('Validator', () {
    test('should pass validation when all rules are satisfied', () {
      final validator = Validator(
        {'name': 'John', 'age': '25'},
        {'name': 'required', 'age': 'required|int'},
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should fail validation when required field is missing', () {
      final validator = Validator(
        {'name': ''},
        {'name': 'required'},
      );

      expect(validator.passes(), isFalse);
      expect(validator.errors, contains('name'));
    });

    test('should fail validation when multiple rules are not satisfied', () {
      final validator = Validator(
        {'age': 'not-a-number'},
        {'age': 'required|int'},
      );

      expect(validator.passes(), isFalse);
      expect(validator.errors, contains('age'));
    });

    test('should throw ValidationException when validate() is called and validation fails', () {
      final validator = Validator(
        {'name': ''},
        {'name': 'required'},
      );

      expect(
        () => validator.validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should not throw ValidationException when validate() is called and validation passes', () {
      final validator = Validator(
        {'name': 'John'},
        {'name': 'required'},
      );

      expect(() => validator.validate(), returnsNormally);
    });

    test('should handle multiple fields with multiple rules', () {
      final validator = Validator(
        {'name': 'John', 'age': '25', 'email': ''},
        {
          'name': 'required',
          'age': 'required|int',
          'email': 'required',
        },
      );

      expect(validator.passes(), isFalse);
      expect(validator.errors, contains('email'));
      expect(validator.errors, isNot(contains('name')));
      expect(validator.errors, isNot(contains('age')));
    });

    test('should skip validation for nullable fields when value is null', () {
      final validator = Validator(
        {'name': null, 'age': null},
        {
          'name': 'nullable|required|string',
          'age': 'nullable|int|min:18',
        },
      );

      expect(validator.passes(), isTrue);
      expect(validator.errors, isEmpty);
    });

    test('should validate nullable fields when value is not null', () {
      final validator = Validator(
        {'name': 'John', 'age': '15'},
        {
          'name': 'nullable|required|string',
          'age': 'nullable|int|min:18',
        },
      );

      expect(validator.passes(), isFalse);
      expect(validator.errors, contains('age'));
      expect(validator.errors, isNot(contains('name')));
    });

    test('should validate non-nullable fields normally', () {
      final validator = Validator(
        {'name': null, 'age': '25'},
        {
          'name': 'required|string',
          'age': 'nullable|int|min:18',
        },
      );

      expect(validator.passes(), isFalse);
      expect(validator.errors, contains('name'));
      expect(validator.errors, isNot(contains('age')));
    });
  });
}
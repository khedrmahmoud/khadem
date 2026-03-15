import 'dart:async';
import 'package:khadem/src/contracts/validation/rule.dart';
import 'package:khadem/src/core/validation/input_validator.dart';
import 'package:khadem/src/core/validation/rule_builder.dart';
import 'package:test/test.dart';

class AsyncTestRule extends Rule {
  @override
  String get signature => 'async_test';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    await Future.delayed(
      const Duration(milliseconds: 10),
    ); // Simulate async work
    return context.value != 'invalid';
  }

  @override
  String message(ValidationContext context) => 'async_error';
}

class ObjectTestRule extends Rule {
  final int max;
  ObjectTestRule(this.max);

  @override
  String get signature => 'object_test';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value is int && value > max) {
      return false;
    }
    return true;
  }

  @override
  String message(ValidationContext context) => 'max_error';
}

void main() {
  group('Flexible InputValidator', () {
    test('should support List<dynamic> rules with mixed strings and objects',
        () async {
      final validator = InputValidator(
        {'age': 25, 'name': 'John'},
        {
          'age': ['required', ObjectTestRule(20)], // 25 > 20, should fail
          'name': ['required', AsyncTestRule()],
        },
      );

      expect(await validator.passes(), isFalse);
      expect(validator.errors, contains('age'));
      expect(
        validator.errors['age'],
        contains('max_error'),
      ); // Assuming default formatting uses key
      expect(validator.errors, isNot(contains('name')));
    });

    test('should support async rules', () async {
      final validator = InputValidator(
        {'field': 'invalid'},
        {'field': AsyncTestRule()},
      );

      expect(await validator.passes(), isFalse);
      expect(validator.errors, contains('field'));
    });

    test('should support mixed string rules in list', () async {
      final validator = InputValidator(
        {'email': 'not-an-email'},
        {
          'email': ['required|email'], // String with pipe inside list
        },
      );
      expect(await validator.passes(), isFalse);
      expect(validator.errors, contains('email'));

      final validator2 = InputValidator(
        {'name': ''},
        {
          'name': ['required'],
        },
      );
      expect(await validator2.passes(), isFalse);
    });

    test('should support RuleBuilder', () async {
      final rules = RuleBuilder().required().min(5).build();
      final validator = InputValidator(
        {'name': 'abc'},
        {'name': rules},
      );
      expect(await validator.passes(), isFalse);
      // 'abc' is length 3, min(5) fails. required passes.
      expect(validator.errors['name']?.length, equals(1));
    });

    test('should support bail', () async {
      final validator = InputValidator(
        {'name': ''},
        {
          'name': ['required', 'bail', 'min:5'],
        },
      );
      expect(await validator.passes(), isFalse);
      // required fails. bail stops. min skipped.
      expect(validator.errors['name']?.length, equals(1));
      expect(validator.errors['name']?.first, contains('required'));
    });

    test('should collect multiple errors without bail', () async {
      final validator = InputValidator(
        {'code': 'abc'},
        {
          'code': ['numeric', 'min:5'],
        },
      );
      expect(await validator.passes(), isFalse);
      // numeric fails (abc is not numeric)
      // min fails (abc length 3 < 5)
      expect(validator.errors['code']?.length, greaterThanOrEqualTo(2));
    });
  });
}

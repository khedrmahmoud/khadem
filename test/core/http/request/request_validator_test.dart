import 'dart:async';

import 'package:test/test.dart';

import '../../../../lib/src/core/http/request/request_body_parser.dart';
import '../../../../lib/src/core/http/request/request_validator.dart';

class FakeRequestBodyParser implements RequestBodyParser {
  final Map<String, dynamic> _data;

  FakeRequestBodyParser(this._data);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #parseBody) {
      return Future.value(_data);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('RequestValidator', () {
    late RequestValidator validator;
    late FakeRequestBodyParser fakeBodyParser;

    setUp(() {
      fakeBodyParser = FakeRequestBodyParser({'name': 'John', 'email': 'john@example.com'});
      validator = RequestValidator(fakeBodyParser as dynamic);
    });

    group('Body Validation', () {
      test('should validate request body', () async {
        final rules = {'name': 'required', 'email': 'required|email'};

        final result = await validator.validateBody(rules);

        expect(result, isNotNull);
        expect(result['name'], equals('John'));
        expect(result['email'], equals('john@example.com'));
      });

      test('should throw validation exception for invalid body', () async {
        fakeBodyParser = FakeRequestBodyParser({'name': '', 'email': 'invalid-email'});
        validator = RequestValidator(fakeBodyParser as dynamic);

        final rules = {'name': 'required', 'email': 'required|email'};

        expect(() async => validator.validateBody(rules), throwsException);
      });
    });

    group('Data Validation', () {
      test('should validate data successfully', () {
        final data = {'name': 'John', 'email': 'john@example.com', 'age': 25};
        final rules = {'name': 'required', 'email': 'required|email', 'age': 'required|integer'};

        final result = validator.validateData(data, rules);

        expect(result, equals(data));
      });

      test('should throw validation exception for invalid data', () {
        final data = {'name': '', 'email': 'invalid-email'};
        final rules = {'name': 'required', 'email': 'required|email'};

        expect(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate required fields', () {
        final data = {'name': 'John'};
        final rules = {'name': 'required', 'email': 'required'};

        expect(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate email format', () {
        final data = {'email': 'invalid-email'};
        final rules = {'email': 'email'};

        expect(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate email format correctly', () {
        final data = {'email': 'john@example.com'};
        final rules = {'email': 'email'};

        final result = validator.validateData(data, rules);

        expect(result, equals(data));
      });

      test('should validate minimum length', () {
        final data = {'name': 'Jo'};
        final rules = {'name': 'min:3'};

        expect(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate maximum length', () {
        final data = {'name': 'VeryLongName'};
        final rules = {'name': 'max:5'};

        expect(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate integer type', () {
        final data = {'age': 25};
        final rules = {'age': 'integer'};

        final result = validator.validateData(data, rules);

        expect(result, equals(data));
      });

      test('should validate minimum value', () {
        final data = {'age': 17};
        final rules = {'age': 'min:18'};

        expect(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate maximum value', () {
        final data = {'score': 150};
        final rules = {'score': 'max:100'};

        expect(() => validator.validateData(data, rules), throwsException);
      });
    });

    group('Edge Cases', () {
      test('should handle empty data', () {
        final data = <String, dynamic>{};
        final rules = {'name': 'required'};

        expect(() => validator.validateData(data, rules), throwsException);
      });

      test('should handle null values', () {
        final data = {'name': null};
        final rules = {'name': 'required'};

        expect(() => validator.validateData(data, rules), throwsException);
      });

      test('should handle empty rules', () {
        final data = {'name': 'John'};
        final rules = <String, String>{};

        final result = validator.validateData(data, rules);

        expect(result, equals(data));
      });
    });
  });
}

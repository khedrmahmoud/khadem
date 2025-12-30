import 'dart:async';

import 'package:khadem/khadem.dart'
    show BodyParser, UploadedFile, RequestValidator;
import 'package:test/test.dart';

class FakeBodyParser implements BodyParser {
  final Map<String, dynamic> _data;
  final Map<String, dynamic>? _files;

  FakeBodyParser(this._data, [this._files]);

  @override
  Map<String, UploadedFile>? get files {
    if (_files == null) return null;
    return _files!.map((key, value) => MapEntry(key, value as UploadedFile));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #parse) {
      return Future.value(_data);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('RequestValidator', () {
    late RequestValidator validator;
    late FakeBodyParser fakeBodyParser;

    setUp(() {
      fakeBodyParser =
          FakeBodyParser({'name': 'John', 'email': 'john@example.com'});
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
        fakeBodyParser = FakeBodyParser({'name': '', 'email': 'invalid-email'});
        validator = RequestValidator(fakeBodyParser as dynamic);

        final rules = {'name': 'required', 'email': 'required|email'};

        expect(() async => validator.validateBody(rules), throwsException);
      });
    });

    group('Data Validation', () {
      test('should validate data successfully', () async {
        final data = {'name': 'John', 'email': 'john@example.com', 'age': 25};
        final rules = {
          'name': 'required',
          'email': 'required|email',
          'age': 'required|int', // Changed integer to int as per registry
        };

        final result = await validator.validateData(data, rules);

        expect(result, equals(data));
      });

      test('should throw validation exception for invalid data', () async {
        final data = {'name': '', 'email': 'invalid-email'};
        final rules = {'name': 'required', 'email': 'required|email'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate required fields', () async {
        final data = {'name': 'John'};
        final rules = {'name': 'required', 'email': 'required'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate email format', () async {
        final data = {'email': 'invalid-email'};
        final rules = {'email': 'email'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate email format correctly', () async {
        final data = {'email': 'john@example.com'};
        final rules = {'email': 'email'};

        final result = await validator.validateData(data, rules);

        expect(result, equals(data));
      });

      test('should validate minimum length', () async {
        final data = {'name': 'Jo'};
        final rules = {'name': 'min:3'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate maximum length', () async {
        final data = {'name': 'VeryLongName'};
        final rules = {'name': 'max:5'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate integer type', () async {
        final data = {'age': 25};
        final rules = {'age': 'int'}; // Changed integer to int

        final result = await validator.validateData(data, rules);

        expect(result, equals(data));
      });

      test('should validate minimum value', () async {
        final data = {'age': 17};
        final rules = {'age': 'min:18'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });

      test('should validate maximum value', () async {
        final data = {'score': 150};
        final rules = {'score': 'max:100'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });
    });

    group('Edge Cases', () {
      test('should handle empty data', () async {
        final data = <String, dynamic>{};
        final rules = {'name': 'required'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });

      test('should handle null values', () async {
        final data = {'name': null};
        final rules = {'name': 'required'};

        await expectLater(() => validator.validateData(data, rules), throwsException);
      });

      test('should handle empty rules', () async {
        final data = {'name': 'John'};
        final rules = <String, String>{};

        final result = await validator.validateData(data, rules);

        expect(result, isEmpty);
      });
    });
  });
}

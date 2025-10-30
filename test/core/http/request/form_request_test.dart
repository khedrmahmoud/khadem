import 'dart:async';
import 'dart:io';

import 'package:khadem/khadem.dart'
    show
        Request,
        RequestBodyParser,
        UploadedFile,
        FormRequest,
        ValidationException,
        UnauthorizedException,
        InputValidator;
import 'package:test/test.dart';

// Fake HttpRequest for testing
class FakeHttpRequest implements HttpRequest {
  @override
  String get method => 'POST';

  @override
  Uri get uri => Uri.parse('http://localhost/test');

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

// Fake RequestBodyParser for testing
class FakeRequestBodyParser implements RequestBodyParser {
  final Map<String, dynamic> _data;
  final Map<String, dynamic>? _files;

  FakeRequestBodyParser(this._data, [this._files]);

  @override
  Map<String, UploadedFile>? get files {
    if (_files == null) return null;
    return _files!.map((key, value) => MapEntry(key, value as UploadedFile));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #parseBody) {
      return Future.value(_data);
    }
    return super.noSuchMethod(invocation);
  }
}

// Fake Request that allows us to control the validated data
class FakeRequest implements Request {
  final Map<String, dynamic> _bodyData;

  FakeRequest(this._bodyData);

  @override
  Future<Map<String, dynamic>> validate(
    Map<String, String> rules, {
    Map<String, String>? messages,
  }) async {
    // Use the real InputValidator for proper testing
    final validator =
        InputValidator(_bodyData, rules, customMessages: messages ?? {});

    if (!validator.passes()) {
      throw ValidationException(validator.errors);
    }

    // Return only the validated data that are in the rules
    return {
      for (var key in rules.keys)
        if (_bodyData.containsKey(key)) key: _bodyData[key],
    };
  }

  // Implement other required methods with minimal functionality
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

// Test FormRequest implementations
class TestFormRequest extends FormRequest {
  @override
  Map<String, String> rules() {
    return {
      'name': 'required|max:50',
      'email': 'required|email',
    };
  }
}

class TestFormRequestWithMessages extends FormRequest {
  @override
  Map<String, String> rules() {
    return {
      'email': 'required|email',
      'password': 'required|min:8',
    };
  }

  @override
  Map<String, String> messages() {
    return {
      'email.required': 'Email is required custom',
      'password.min': 'Password must be at least 8 chars custom',
    };
  }
}

class TestFormRequestWithHooks extends FormRequest {
  bool prepareWasCalled = false;
  bool passedWasCalled = false;
  bool failedWasCalled = false;

  @override
  Map<String, String> rules() {
    return {'name': 'required'};
  }

  @override
  void prepareForValidation(Request request) {
    prepareWasCalled = true;
  }

  @override
  void passedValidation(Map<String, dynamic> validated) {
    passedWasCalled = true;
    validated['processed'] = true;
  }

  @override
  void failedValidation(Map<String, String> errors) {
    failedWasCalled = true;
    super.failedValidation(errors);
  }
}

class TestFormRequestWithAuth extends FormRequest {
  final bool shouldAuthorize;

  TestFormRequestWithAuth({this.shouldAuthorize = true});

  @override
  Map<String, String> rules() {
    return {'name': 'required'};
  }

  @override
  bool authorize(Request request) {
    return shouldAuthorize;
  }
}

class EmptyRulesFormRequest extends FormRequest {
  @override
  Map<String, String> rules() {
    return {};
  }
}

class TestFormRequestWithNumeric extends FormRequest {
  @override
  Map<String, String> rules() {
    return {
      'name': 'required|max:50',
      'email': 'required|email',
      'age': 'required|numeric|min:18|max:120',
    };
  }
}

class TestFormRequestWithOrderedHooks extends FormRequest {
  List<String> callOrder = [];

  @override
  Map<String, String> rules() {
    return {'name': 'required'};
  }

  @override
  bool authorize(Request request) {
    callOrder.add('authorize');
    return true;
  }

  @override
  void prepareForValidation(Request request) {
    callOrder.add('prepare');
  }

  @override
  void passedValidation(Map<String, dynamic> validated) {
    callOrder.add('passed');
  }

  @override
  void failedValidation(Map<String, String> errors) {
    callOrder.add('failed');
    super.failedValidation(errors);
  }
}

class TestFormRequestWithRequestCheck extends FormRequest {
  Request? receivedRequest;

  @override
  Map<String, String> rules() {
    return {'name': 'required'};
  }

  @override
  void prepareForValidation(Request request) {
    receivedRequest = request;
  }
}

class TestFormRequestWithDataModification extends FormRequest {
  @override
  Map<String, String> rules() {
    return {
      'name': 'required',
      'email': 'required|email',
    };
  }

  @override
  void passedValidation(Map<String, dynamic> validated) {
    validated['modified'] = true;
    validated['timestamp'] = DateTime.now().toIso8601String();
  }
}

class TestFormRequestWithAuthCheck extends FormRequest {
  Request? authorizedRequest;

  @override
  Map<String, String> rules() {
    return {'name': 'required'};
  }

  @override
  bool authorize(Request request) {
    authorizedRequest = request;
    return true;
  }
}

class TestFormRequestComplex extends FormRequest {
  @override
  Map<String, String> rules() {
    return {
      'name': 'required|string|max:100',
      'email': 'required|email',
      'age': 'required|numeric|min:18|max:120',
      'password': 'required|min:8',
    };
  }
}

class CustomTestException implements Exception {
  final String message;
  CustomTestException(this.message);

  @override
  String toString() => 'CustomTestException: $message';
}

class TestFormRequestWithCustomException extends FormRequest {
  @override
  Map<String, String> rules() {
    return {'name': 'required'};
  }

  @override
  void failedValidation(Map<String, String> errors) {
    throw CustomTestException('Custom validation failure');
  }
}

void main() {
  group('FormRequest', () {
    group('Basic Validation', () {
      test('validates successfully with valid data', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        final validated = await formRequest.validate(request);

        expect(validated['name'], equals('John Doe'));
        expect(validated['email'], equals('john@example.com'));
        expect(formRequest.hasValidated(), isTrue);
      });

      test('throws ValidationException with invalid data', () async {
        final request = FakeRequest({
          'name': '',
          'email': 'invalid-email',
        });

        final formRequest = TestFormRequest();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<ValidationException>()),
        );
        expect(formRequest.hasValidated(), isFalse);
      });

      test('enforces max length validation', () async {
        final request = FakeRequest({
          'name': 'A' * 51,
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<ValidationException>()),
        );
      });

      test('enforces required validation', () async {
        final request = FakeRequest({
          'name': '',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validates with empty rules map', () async {
        final request = FakeRequest({'any': 'data'});

        final formRequest = EmptyRulesFormRequest();
        final validated = await formRequest.validate(request);

        expect(validated, isEmpty);
        expect(formRequest.hasValidated(), isTrue);
      });

      test('handles multiple validation failures', () async {
        final request = FakeRequest({
          'name': '',
          'email': 'invalid-email',
        });

        final formRequest = TestFormRequest();

        try {
          await formRequest.validate(request);
          fail('Should have thrown ValidationException');
        } catch (e) {
          expect(e, isA<ValidationException>());
          final errors = (e as ValidationException).errors;
          expect(errors.length, greaterThanOrEqualTo(1));
          expect(errors.containsKey('name') || errors.containsKey('email'),
              isTrue,);
        }
      });

      test('validates numeric fields correctly', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 25,
        });

        final formRequest = TestFormRequestWithNumeric();
        final validated = await formRequest.validate(request);

        expect(validated['age'], equals(25));
      });

      test('fails validation for non-numeric age', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 'not-a-number',
        });

        final formRequest = TestFormRequestWithNumeric();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('Custom Messages', () {
      test('validates successfully with custom messages', () async {
        final request = FakeRequest({
          'email': 'test@example.com',
          'password': 'password123',
        });

        final formRequest = TestFormRequestWithMessages();
        final validated = await formRequest.validate(request);

        expect(validated['email'], equals('test@example.com'));
        expect(validated['password'], equals('password123'));
      });

      test('validates successfully with custom messages', () async {
        final request = FakeRequest({
          'email': 'test@example.com',
          'password': 'password123',
        });

        final formRequest = TestFormRequestWithMessages();
        final validated = await formRequest.validate(request);

        expect(validated['email'], equals('test@example.com'));
        expect(validated['password'], equals('password123'));
      });

      test('uses custom error messages when provided', () async {
        final request = FakeRequest({
          'email': '',
          'password': 'abc',
        });

        final formRequest = TestFormRequestWithMessages();

        try {
          await formRequest.validate(request);
          fail('Should have thrown ValidationException');
        } catch (e) {
          expect(e, isA<ValidationException>());
          final errors = (e as ValidationException).errors;

          // Check that custom messages are actually used
          expect(errors.containsKey('email'), isTrue);
          expect(errors.containsKey('password'), isTrue);

          // The custom messages should be used instead of default ones
          expect(errors['email'], contains('Email is required custom'));
          expect(errors['password'],
              contains('Password must be at least 8 chars custom'),);
        }
      });
    });

    group('Lifecycle Hooks', () {
      test('calls prepareForValidation before validation', () async {
        final request = FakeRequest({'name': 'John Doe'});

        final formRequest = TestFormRequestWithHooks();
        await formRequest.validate(request);

        expect(formRequest.prepareWasCalled, isTrue);
      });

      test('calls passedValidation after successful validation', () async {
        final request = FakeRequest({'name': 'John Doe'});

        final formRequest = TestFormRequestWithHooks();
        final validated = await formRequest.validate(request);

        expect(formRequest.passedWasCalled, isTrue);
        expect(validated['processed'], isTrue);
      });

      test('calls failedValidation on validation failure', () async {
        final request = FakeRequest({'name': ''});

        final formRequest = TestFormRequestWithHooks();

        try {
          await formRequest.validate(request);
          fail('Should have thrown ValidationException');
        } catch (e) {
          expect(formRequest.failedWasCalled, isTrue);
          expect(formRequest.passedWasCalled, isFalse);
        }
      });

      test('failedValidation re-throws ValidationException by default',
          () async {
        final request = FakeRequest({'name': ''});

        final formRequest = TestFormRequestWithHooks();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<ValidationException>()),
        );
      });

      test('calls hooks in correct order', () async {
        final request = FakeRequest({'name': 'John Doe'});

        final formRequest = TestFormRequestWithOrderedHooks();
        await formRequest.validate(request);

        expect(
            formRequest.callOrder, equals(['authorize', 'prepare', 'passed']),);
      });

      test('calls hooks in correct order on failure', () async {
        final request = FakeRequest({'name': ''});

        final formRequest = TestFormRequestWithOrderedHooks();

        try {
          await formRequest.validate(request);
        } catch (e) {
          expect(formRequest.callOrder,
              equals(['authorize', 'prepare', 'failed']),);
        }
      });

      test('prepareForValidation receives correct request instance', () async {
        final request = FakeRequest({'name': 'John Doe'});

        final formRequest = TestFormRequestWithRequestCheck();
        await formRequest.validate(request);

        expect(formRequest.receivedRequest, equals(request));
      });

      test('passedValidation can modify validated data', () async {
        final request =
            FakeRequest({'name': 'John Doe', 'email': 'john@example.com'});

        final formRequest = TestFormRequestWithDataModification();
        final validated = await formRequest.validate(request);

        expect(validated['name'], equals('John Doe'));
        expect(validated['email'], equals('john@example.com'));
        expect(validated['modified'], isTrue);
        expect(validated['timestamp'], isA<String>());
      });
    });

    group('Authorization', () {
      test('throws UnauthorizedException when authorize returns false',
          () async {
        final request = FakeRequest({'name': 'John Doe'});

        final formRequest = TestFormRequestWithAuth(shouldAuthorize: false);

        expect(
          () => formRequest.validate(request),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('validates successfully when authorize returns true', () async {
        final request = FakeRequest({'name': 'John Doe'});

        final formRequest = TestFormRequestWithAuth();
        final validated = await formRequest.validate(request);

        expect(validated['name'], equals('John Doe'));
      });

      test('checks authorization before validation', () async {
        final request = FakeRequest({'name': ''});

        final formRequest = TestFormRequestWithAuth(shouldAuthorize: false);

        // Should throw UnauthorizedException, not ValidationException
        expect(
          () => formRequest.validate(request),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('authorize receives correct request instance', () async {
        final request = FakeRequest({'name': 'John Doe'});

        final formRequest = TestFormRequestWithAuthCheck();
        await formRequest.validate(request);

        expect(formRequest.authorizedRequest, equals(request));
      });

      test('default authorize returns true', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        final validated = await formRequest.validate(request);

        expect(validated['name'], equals('John Doe'));
      });
    });

    group('Helper Methods', () {
      test('validatedData returns null before validation', () {
        final formRequest = TestFormRequest();
        expect(formRequest.validatedData, isNull);
      });

      test('validatedData returns data after validation', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        await formRequest.validate(request);

        expect(formRequest.validatedData, isNotNull);
        expect(formRequest.validatedData!['name'], equals('John Doe'));
      });

      test('validatedInput returns specific field value', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        await formRequest.validate(request);

        expect(formRequest.validatedInput('name'), equals('John Doe'));
        expect(formRequest.validatedInput('email'), equals('john@example.com'));
        expect(formRequest.validatedInput('nonexistent'), isNull);
      });

      test('validatedInput returns default value for missing fields', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        await formRequest.validate(request);

        expect(
          formRequest.validatedInput('missing', defaultValue: 'default'),
          equals('default'),
        );
      });

      test('validatedInput returns null for missing fields without default',
          () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        await formRequest.validate(request);

        expect(formRequest.validatedInput('missing'), isNull);
      });

      test('only returns specified fields', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        await formRequest.validate(request);

        final result = formRequest.only(['name']);

        expect(result.keys, hasLength(1));
        expect(result['name'], equals('John Doe'));
        expect(result.containsKey('email'), isFalse);
      });

      test('only returns empty map when no validated data', () {
        final formRequest = TestFormRequest();
        final result = formRequest.only(['name']);

        expect(result, isEmpty);
      });

      test('only handles non-existent fields gracefully', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        await formRequest.validate(request);

        final result = formRequest.only(['name', 'nonexistent']);

        expect(result.keys, hasLength(1));
        expect(result['name'], equals('John Doe'));
      });

      test('except returns all fields except specified', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        await formRequest.validate(request);

        final result = formRequest.except(['email']);

        expect(result.keys, hasLength(1));
        expect(result['name'], equals('John Doe'));
        expect(result.containsKey('email'), isFalse);
      });

      test('except returns empty map when no validated data', () {
        final formRequest = TestFormRequest();
        final result = formRequest.except(['email']);

        expect(result, isEmpty);
      });

      test('except handles non-existent fields gracefully', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        await formRequest.validate(request);

        final result = formRequest.except(['nonexistent']);

        expect(result.keys, hasLength(2));
        expect(result['name'], equals('John Doe'));
        expect(result['email'], equals('john@example.com'));
      });

      test('hasValidated returns correct state', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        expect(formRequest.hasValidated(), isFalse);

        await formRequest.validate(request);
        expect(formRequest.hasValidated(), isTrue);
      });

      test('request returns the underlying Request instance', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();
        expect(formRequest.request, isNull);

        await formRequest.validate(request);
        expect(formRequest.request, equals(request));
      });

      test('request returns the request instance even when validation fails',
          () async {
        final request = FakeRequest({
          'name': '',
        });

        final formRequest = TestFormRequest();
        expect(formRequest.request, isNull);

        try {
          await formRequest.validate(request);
        } catch (e) {
          expect(formRequest.request, equals(request));
        }
      });
    });

    group('Edge Cases', () {
      test('handles revalidation with different data', () async {
        final formRequest = TestFormRequest();

        final request1 = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        await formRequest.validate(request1);
        expect(formRequest.validatedInput('name'), equals('John Doe'));

        final request2 = FakeRequest({
          'name': 'Jane Smith',
          'email': 'jane@example.com',
        });

        await formRequest.validate(request2);
        expect(formRequest.validatedInput('name'), equals('Jane Smith'));
      });

      test('validated data is updated on revalidation', () async {
        final formRequest = TestFormRequest();

        final request1 =
            FakeRequest({'name': 'John', 'email': 'john@example.com'});
        await formRequest.validate(request1);

        final firstValidated = formRequest.validatedData;

        final request2 =
            FakeRequest({'name': 'Jane', 'email': 'jane@example.com'});
        await formRequest.validate(request2);

        final secondValidated = formRequest.validatedData;

        expect(firstValidated, isNot(equals(secondValidated)));
        expect(secondValidated!['name'], equals('Jane'));
      });

      test('handles validation with null values in request', () async {
        final request = FakeRequest({
          'name': null,
          'email': 'john@example.com',
        });

        final formRequest = TestFormRequest();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<ValidationException>()),
        );
      });

      test('handles empty request data', () async {
        final request = FakeRequest({});

        final formRequest = TestFormRequest();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<ValidationException>()),
        );
      });

      test('handles complex validation rules', () async {
        final request = FakeRequest({
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 25,
          'password': 'password123',
        });

        final formRequest = TestFormRequestComplex();
        final validated = await formRequest.validate(request);

        expect(validated['name'], equals('John Doe'));
        expect(validated['email'], equals('john@example.com'));
        expect(validated['age'], equals(25));
        expect(validated['password'], equals('password123'));
      });

      test('fails complex validation with invalid data', () async {
        final request = FakeRequest({
          'name': 'John',
          'email': 'invalid-email',
          'age': 15,
          'password': '123',
        });

        final formRequest = TestFormRequestComplex();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('Exception Handling', () {
      test('ValidationException contains field-specific errors', () async {
        final request = FakeRequest({
          'name': '',
          'email': 'invalid-email',
        });

        final formRequest = TestFormRequest();

        try {
          await formRequest.validate(request);
          fail('Should have thrown ValidationException');
        } catch (e) {
          expect(e, isA<ValidationException>());
          final validationException = e as ValidationException;
          expect(validationException.errors, isA<Map<String, String>>());
          expect(validationException.errors.isNotEmpty, isTrue);
        }
      });

      test('UnauthorizedException has default message', () async {
        final request = FakeRequest({'name': 'John Doe'});

        final formRequest = TestFormRequestWithAuth(shouldAuthorize: false);

        try {
          await formRequest.validate(request);
          fail('Should have thrown UnauthorizedException');
        } catch (e) {
          expect(e, isA<UnauthorizedException>());
          final unauthorizedException = e as UnauthorizedException;
          expect(unauthorizedException.message,
              equals('This action is unauthorized.'),);
        }
      });

      test('failedValidation can throw custom exceptions', () async {
        final request = FakeRequest({'name': ''});

        final formRequest = TestFormRequestWithCustomException();

        expect(
          () => formRequest.validate(request),
          throwsA(isA<CustomTestException>()),
        );
      });
    });
  });
}

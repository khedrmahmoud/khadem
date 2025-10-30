import 'package:khadem/src/modules/auth/exceptions/auth_exception.dart';
import 'package:test/test.dart';

void main() {
  group('AuthException', () {
    test('should create exception with message', () {
      final exception = AuthException('Test error message');
      expect(exception.message, equals('Test error message'));
      expect(exception.statusCode, equals(401)); // default
      expect(exception.details, isNull);
    });

    test('should create exception with custom status code', () {
      final exception = AuthException('Forbidden', statusCode: 403);
      expect(exception.message, equals('Forbidden'));
      expect(exception.statusCode, equals(403));
    });

    test('should create exception with stack trace', () {
      const stackTrace = 'Mock stack trace';
      final exception =
          AuthException('Error with stack', stackTrace: stackTrace);
      expect(exception.message, equals('Error with stack'));
      expect(exception.details, equals(stackTrace));
    });

    test('should convert to response map', () {
      final exception = AuthException('Test error');
      final response = exception.toResponse();
      expect(response['message'], equals('Test error'));
      expect(response.containsKey('details'), isFalse);
    });

    test('should convert to response map with details', () {
      final exception = AuthException('Test error', stackTrace: 'stack trace');
      final response = exception.toResponse();
      expect(response['message'], equals('Test error'));
      expect(response['details'], equals('stack trace'));
    });

    test('should handle empty message', () {
      final exception = AuthException('');
      expect(exception.message, equals(''));
      expect(exception.statusCode, equals(401));
    });
  });
}

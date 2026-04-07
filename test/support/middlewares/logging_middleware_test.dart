import 'package:khadem/src/support/middlewares/logging_middleware.dart';
import 'package:test/test.dart';

void main() {
  group('LoggingMiddleware URI sanitization', () {
    test('redacts sensitive query values', () {
      final uri = Uri.parse(
        'https://example.test/login?email=user@example.com&password=secret&token=abc123',
      );

      final sanitized = LoggingMiddleware.sanitizeUriForLogging(uri);

      expect(sanitized, contains('email=user%40example.com'));
      expect(sanitized, contains('password=%5BREDACTED%5D'));
      expect(sanitized, contains('token=%5BREDACTED%5D'));
      expect(sanitized, isNot(contains('secret')));
      expect(sanitized, isNot(contains('abc123')));
    });

    test('keeps non-sensitive query values unchanged', () {
      final uri = Uri.parse('https://example.test/items?page=2&sort=desc');
      final sanitized = LoggingMiddleware.sanitizeUriForLogging(uri);

      expect(sanitized, contains('page=2'));
      expect(sanitized, contains('sort=desc'));
    });

    test('works with uris without query parameters', () {
      final uri = Uri.parse('https://example.test/health');
      final sanitized = LoggingMiddleware.sanitizeUriForLogging(uri);

      expect(sanitized, equals('https://example.test/health'));
    });
  });
}

import 'package:khadem/src/core/exception/exception_reporter.dart';
import 'package:test/test.dart';

void main() {
  group('ExceptionReporter sanitization', () {
    test('sanitizeHeadersForLogging redacts sensitive headers', () {
      final sanitized = ExceptionReporter.sanitizeHeadersForLogging({
        'authorization': 'Bearer secret-token',
        'cookie': 'sid=abc',
        'x-request-id': 'trace-1',
      });

      expect(sanitized['authorization'], '[REDACTED]');
      expect(sanitized['cookie'], '[REDACTED]');
      expect(sanitized['x-request-id'], 'trace-1');
    });

    test('sanitizeUriForLogging redacts sensitive query keys', () {
      final sanitized = ExceptionReporter.sanitizeUriForLogging(
        Uri.parse('https://example.com/callback?token=abc&mode=full'),
      );

      expect(sanitized, contains('token=%5BREDACTED%5D'));
      expect(sanitized, contains('mode=full'));
    });

    test('sanitizeContextForLogging redacts nested sensitive fields', () {
      final sanitized = ExceptionReporter.sanitizeContextForLogging({
        'user': {'email': 'user@example.com', 'password': 'plain-text'},
        'payload': [
          {'refresh_token': 'rt-1', 'value': 42},
        ],
      });

      final user = sanitized['user'] as Map<String, dynamic>;
      final payload = sanitized['payload'] as List<dynamic>;
      final firstPayload = payload.first as Map<String, dynamic>;

      expect(user['email'], 'user@example.com');
      expect(user['password'], '[REDACTED]');
      expect(firstPayload['refresh_token'], '[REDACTED]');
      expect(firstPayload['value'], 42);
    });
  });
}

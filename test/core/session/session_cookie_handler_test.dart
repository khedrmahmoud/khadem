import 'dart:io';

import 'package:khadem/src/core/session/session_cookie_handler.dart';
import 'package:test/test.dart';

void main() {
  group('SessionCookieHandler', () {
    late SessionCookieHandler cookieHandler;
    late HttpRequest mockRequest;
    late HttpResponse mockResponse;

    setUp(() {
      cookieHandler = SessionCookieHandler();
      mockRequest = _MockHttpRequest();
      mockResponse = _MockHttpResponse();
    });

    test('should extract session ID from request cookies', () {
      const sessionId = 'test_session_123';
      final cookie = Cookie('khadem_session', sessionId);
      (mockRequest as _MockHttpRequest).cookies.add(cookie);

      final extractedId = cookieHandler.getSessionIdFromRequest(mockRequest);
      expect(extractedId, equals(sessionId));
    });

    test('should return null when session cookie is not present', () {
      final extractedId = cookieHandler.getSessionIdFromRequest(mockRequest);
      expect(extractedId, isNull);
    });

    test('should set session cookie in response', () {
      const sessionId = 'test_session_456';
      cookieHandler.setSessionCookie(mockResponse, sessionId);

      final cookies = (mockResponse as _MockHttpResponse).cookies;
      expect(cookies, hasLength(1));

      final cookie = cookies.first;
      expect(cookie.name, equals('khadem_session'));
      expect(cookie.value, equals(sessionId));
      expect(cookie.httpOnly, isTrue);
      expect(cookie.path, equals('/'));
    });

    test('should set custom max age for session cookie', () {
      const sessionId = 'test_session_custom';
      const customMaxAge = Duration(hours: 2);

      cookieHandler.setSessionCookie(mockResponse, sessionId,
          maxAge: customMaxAge,);

      final cookies = (mockResponse as _MockHttpResponse).cookies;
      expect(cookies, hasLength(1));

      final cookie = cookies.first;
      expect(cookie.maxAge, equals(customMaxAge.inSeconds));
    });

    test('should clear session cookie', () {
      cookieHandler.clearSessionCookie(mockResponse);

      final cookies = (mockResponse as _MockHttpResponse).cookies;
      expect(cookies, hasLength(1));

      final cookie = cookies.first;
      expect(cookie.name, equals('khadem_session'));
      expect(cookie.value, isEmpty);
      expect(cookie.maxAge, equals(0));
      expect(cookie.expires, isNotNull);
      expect(cookie.path, equals('/'));
    });

    test('should handle custom cookie configuration', () {
      final customHandler = SessionCookieHandler(
        cookieName: 'custom_session',
        defaultMaxAge: const Duration(hours: 12),
        secure: true,
        httpOnly: false,
        sameSite: 'strict',
        domain: 'example.com',
      );

      const sessionId = 'custom_test_session';
      customHandler.setSessionCookie(mockResponse, sessionId);

      final cookies = (mockResponse as _MockHttpResponse).cookies;
      expect(cookies, hasLength(1));

      final cookie = cookies.first;
      expect(cookie.name, equals('custom_session'));
      expect(cookie.value, equals(sessionId));
      expect(cookie.httpOnly, isFalse);
      expect(cookie.secure, isTrue);
      expect(cookie.domain, equals('example.com'));
    });
  });
}

// Mock classes for testing
class _MockHttpRequest implements HttpRequest {
  @override
  final List<Cookie> cookies = [];

  // Implement other required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpResponse implements HttpResponse {
  @override
  final List<Cookie> cookies = [];

  // Implement other required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

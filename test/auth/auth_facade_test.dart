import 'package:khadem/src/core/http/request/request.dart';
import 'package:khadem/src/modules/auth/auth.dart';
import 'package:khadem/src/modules/auth/core/request_auth.dart';
import 'package:test/test.dart';

import '../mocks/auth_facade_test.fakes.dart';

void main() {
  group('Auth Facade', () {
    late Request request;
    late Auth auth;

    setUp(() {
      final mockHttpRequest = FakeHttpRequest();
      request = Request(mockHttpRequest);
      auth = Auth(request);
    });

    test('should return null user when not authenticated', () {
      expect(auth.user, isNull);
      expect(auth.id, isNull);
      expect(auth.check, isFalse);
      expect(auth.guest, isTrue);
    });

    test('should return user data when authenticated', () {
      final userData = {
        'id': 1,
        'email': 'test@example.com',
        'name': 'Test User',
      };

      request.setUser(userData);

      expect(auth.user, equals(userData));
      expect(auth.id, equals(1));
      expect(auth.check, isTrue);
      expect(auth.guest, isFalse);
    });

    test('should handle null request', () {
      final nullAuth = Auth();

      expect(nullAuth.user, isNull);
      expect(nullAuth.id, isNull);
      expect(nullAuth.check, isFalse);
      expect(nullAuth.guest, isTrue);
    });

    test('should work with default constructor', () {
      final defaultAuth = Auth();

      expect(defaultAuth.user, isNull);
      expect(defaultAuth.id, isNull);
      expect(defaultAuth.check, isFalse);
      expect(defaultAuth.guest, isTrue);
    });
  });
}

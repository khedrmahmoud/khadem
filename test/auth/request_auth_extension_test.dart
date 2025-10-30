import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:khadem/src/core/http/request/request.dart';
import 'package:khadem/src/modules/auth/contracts/authenticatable.dart';
import 'package:khadem/src/modules/auth/core/request_auth.dart';
import 'package:test/test.dart';

class FakeHttpRequest extends Stream<Uint8List> implements HttpRequest {
  @override
  String method = 'GET';

  @override
  Uri uri = Uri.parse('/test?param=value');

  @override
  HttpHeaders headers = FakeHttpHeaders();

  @override
  HttpSession session = FakeHttpSession();

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    // Return a subscription with some dummy JSON data
    final data = Uint8List.fromList('{"name": "test", "value": 123}'.codeUnits);
    return Stream<Uint8List>.fromIterable([data]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {
    'content-type': ['application/json'],
    'user-agent': ['TestAgent/1.0'],
    'accept': ['application/json'],
  };

  @override
  bool get chunkedTransferEncoding => false;

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = name.toLowerCase();
    _headers[key] ??= [];
    _headers[key]!.add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = name.toLowerCase();
    _headers[key] = [value.toString()];
  }

  @override
  void remove(String name, Object value) {
    final key = name.toLowerCase();
    _headers[key]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _headers.remove(name.toLowerCase());
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  String? value(String name) => _headers[name.toLowerCase()]?.first;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpSession implements HttpSession {
  final Map<String, dynamic> _data = {};

  @override
  String get id => 'test_session_id';

  @override
  bool get isNew => true;

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  void operator []=(Object? key, dynamic value) {
    _data[key as String] = value;
  }

  @override
  bool containsKey(Object? key) => _data.containsKey(key);

  @override
  dynamic remove(Object? key) => _data.remove(key);

  @override
  void destroy() {
    _data.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockAuthenticatable implements Authenticatable {
  @override
  dynamic getAuthIdentifier() => 1;

  @override
  String getAuthIdentifierName() => 'id';

  @override
  String? getAuthPassword() => 'hashed_password';

  @override
  Map<String, dynamic> toAuthArray() {
    return {
      'id': 1,
      'email': 'test@example.com',
      'name': 'Test User',
      'roles': ['user'],
      'permissions': ['read'],
    };
  }
}

void main() {
  group('RequestAuth Extension', () {
    late Request request;

    setUp(() {
      // Create a mock HttpRequest for testing
      final mockHttpRequest = FakeHttpRequest();
      request = Request(mockHttpRequest);
    });

    test('should return null user when not authenticated', () {
      expect(request.user, isNull);
      expect(request.isAuthenticated, isFalse);
      expect(request.isGuest, isTrue);
    });

    test('should set and get user correctly', () {
      final userData = {
        'id': 1,
        'email': 'test@example.com',
        'name': 'Test User',
        'roles': ['user'],
        'permissions': ['read'],
      };

      request.setUser(userData);

      expect(request.user, equals(userData));
      expect(request.userId, equals(1));
      expect(request.userEmail, equals('test@example.com'));
      expect(request.userName, equals('Test User'));
      expect(request.isAuthenticated, isTrue);
      expect(request.isGuest, isFalse);
    });

    test('should set authenticatable user correctly', () {
      final authenticatable = MockAuthenticatable();
      request.setAuthenticatable(authenticatable);

      expect(request.userId, equals(1));
      expect(request.userEmail, equals('test@example.com'));
      expect(request.userName, equals('Test User'));
      expect(request.hasRole('user'), isTrue);
      expect(request.hasPermission('read'), isTrue);
    });

    test('should clear user correctly', () {
      final userData = {'id': 1, 'email': 'test@example.com'};
      request.setUser(userData);

      expect(request.isAuthenticated, isTrue);

      request.clearUser();

      expect(request.user, isNull);
      expect(request.isAuthenticated, isFalse);
      expect(request.isGuest, isTrue);
    });

    test('should check roles correctly', () {
      final userData = {
        'id': 1,
        'roles': ['user', 'admin'],
      };
      request.setUser(userData);

      expect(request.hasRole('user'), isTrue);
      expect(request.hasRole('admin'), isTrue);
      expect(request.hasRole('super_admin'), isFalse);

      expect(request.hasAnyRole(['user', 'moderator']), isTrue);
      expect(request.hasAnyRole(['moderator', 'editor']), isFalse);

      expect(request.hasAllRoles(['user', 'admin']), isTrue);
      expect(request.hasAllRoles(['user', 'super_admin']), isFalse);
    });

    test('should check permissions correctly', () {
      final userData = {
        'id': 1,
        'roles': ['admin'],
        'permissions': ['read', 'write'],
      };
      request.setUser(userData);

      expect(request.hasPermission('read'), isTrue);
      expect(request.hasPermission('write'), isTrue);
      // Admin should have all permissions, including ones not explicitly listed
      expect(request.hasPermission('delete'), isTrue);
      expect(request.hasPermission('any_permission'), isTrue);

      expect(request.hasAnyPermission(['read', 'delete']), isTrue);
      expect(request.hasAnyPermission(['delete', 'update']),
          isTrue,); // Admin has all permissions

      expect(request.hasAllPermissions(['read', 'write']), isTrue);
      expect(request.hasAllPermissions(['read', 'delete']),
          isTrue,); // Admin has all permissions
    });

    test('should check ownership correctly', () {
      final userData = {'id': 1};
      request.setUser(userData);

      expect(request.ownsResource(1), isTrue);
      expect(request.ownsResource(2), isFalse);
      expect(request.ownsResource(null), isFalse);
    });

    test('should check admin privileges correctly', () {
      // Regular user
      request.setUser({
        'id': 1,
        'roles': ['user'],
      });
      expect(request.isAdmin, isFalse);
      expect(request.isSuperAdmin, isFalse);
      expect(request.canAccessAdmin(), isFalse);

      // Admin user
      request.setUser({
        'id': 1,
        'roles': ['admin'],
      });
      expect(request.isAdmin, isTrue);
      expect(request.isSuperAdmin, isFalse);
      expect(request.canAccessAdmin(), isTrue);

      // Super admin user
      request.setUser({
        'id': 1,
        'roles': ['super_admin'],
      });
      expect(request.isAdmin, isTrue);
      expect(request.isSuperAdmin, isTrue);
      expect(request.canAccessAdmin(), isTrue);
    });

    test('should handle user metadata correctly', () {
      final userData = {
        'id': 1,
        'meta': {'theme': 'dark', 'language': 'en'},
      };
      request.setUser(userData);

      expect(request.getUserMeta('theme'), equals('dark'));
      expect(request.getUserMeta('language'), equals('en'));
      expect(request.getUserMeta('nonexistent'), isNull);

      request.setUserMeta('timezone', 'UTC');
      expect(request.getUserMeta('timezone'), equals('UTC'));
    });

    test('should handle guard and token correctly', () {
      request.setGuard('api');
      request.setToken('jwt_token_123');

      expect(request.guard, equals('api'));
      expect(request.token, equals('jwt_token_123'));
    });

    test('should extract bearer token correctly', () {
      // Mock request with authorization header
      // This would need proper mocking of HttpRequest
      // For now, test the logic with a mock setup
      expect(request.bearerToken, isNull); // No header set
    });

    test('should check authentication attempts correctly', () {
      // Mock request with credentials
      // This would need proper mocking
      expect(request.isAttemptingAuth, isFalse); // No credentials
    });

    test('should provide auth context correctly', () {
      final userData = {
        'id': 1,
        'email': 'test@example.com',
      };
      request.setUser(userData);
      request.setGuard('api');

      final context = request.authContext;

      expect(context['user_id'], equals(1));
      expect(context['user_email'], equals('test@example.com'));
      expect(context['is_authenticated'], isTrue);
      expect(context['guard'], equals('api'));
      expect(context.containsKey('timestamp'), isTrue);
      expect(context.containsKey('path'), isTrue);
      expect(context.containsKey('method'), isTrue);
    });

    test('should throw auth exceptions correctly', () {
      expect(() => request.requireAuth(), throwsA(isA<Exception>()));
      expect(() => request.requireAdmin(), throwsA(isA<Exception>()));
      expect(() => request.requireSuperAdmin(), throwsA(isA<Exception>()));
      expect(() => request.requireRole('admin'), throwsA(isA<Exception>()));
      expect(
          () => request.requirePermission('read'), throwsA(isA<Exception>()),);
      expect(() => request.requireOwnership(2), throwsA(isA<Exception>()));
    });

    test('should not throw auth exceptions when authenticated', () {
      final userData = {
        'id': 1,
        'roles': ['admin'],
        'permissions': ['read'],
      };
      request.setUser(userData);

      expect(() => request.requireAuth(), returnsNormally);
      expect(() => request.requireAdmin(), returnsNormally);
      expect(() => request.requireRole('admin'), returnsNormally);
      expect(() => request.requirePermission('read'), returnsNormally);
      expect(() => request.requireOwnership(1), returnsNormally);
    });

    test('should record and check recent authentication', () {
      expect(request.wasRecentlyAuthenticated, isFalse);

      request.recordAuthTime();

      expect(request.wasRecentlyAuthenticated, isTrue);
    });
  });
}

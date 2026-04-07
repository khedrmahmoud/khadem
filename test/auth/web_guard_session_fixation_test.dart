import 'dart:io';

import 'package:khadem/src/contracts/session/session_interfaces.dart';
import 'package:khadem/src/modules/auth/config/khadem_auth_config.dart';
import 'package:khadem/src/modules/auth/contracts/authenticatable.dart';
import 'package:khadem/src/modules/auth/core/auth_response.dart';
import 'package:khadem/src/modules/auth/drivers/auth_driver.dart';
import 'package:khadem/src/modules/auth/factories/token_invalidation_strategy_factory.dart';
import 'package:khadem/src/modules/auth/guards/web_guard.dart';
import 'package:test/test.dart';

class _FakeAuthDriver implements AuthDriver {
  @override
  Future<AuthResponse> generateTokens(Authenticatable user) async {
    return AuthResponse(
      user: {'id': user.getAuthIdentifier()},
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
  }

  @override
  Future<AuthResponse> authenticate(
    Map<String, dynamic> credentials,
    Authenticatable user,
  ) async {
    return generateTokens(user);
  }

  @override
  Future<Authenticatable> verifyToken(String token) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    throw UnimplementedError();
  }

  @override
  Future<void> invalidateToken(String token) async {}

  @override
  Future<void> logoutFromAllDevices(String token) async {}

  @override
  Future<void> invalidateTokenWithStrategy(
    String token,
    LogoutType logoutType,
  ) async {}

  @override
  bool validateTokenFormat(String token) => true;
}

class _FakeSessionManager implements ISessionManager {
  final List<String> regeneratedSessionIds = [];
  final Map<String, Map<String, dynamic>> sessionValues = {};
  final List<Map<String, String>> removedValues = [];

  @override
  Future<String> regenerateSession(String oldSessionId) async {
    regeneratedSessionIds.add(oldSessionId);
    final newId = '${oldSessionId}_rotated';
    sessionValues[newId] = Map<String, dynamic>.from(
      sessionValues[oldSessionId] ?? {},
    );
    return newId;
  }

  @override
  Future<void> setSessionValue(
    String sessionId,
    String key,
    dynamic value,
  ) async {
    sessionValues.putIfAbsent(sessionId, () => <String, dynamic>{});
    sessionValues[sessionId]![key] = value;
  }

  @override
  Future<void> removeSessionValue(String sessionId, String key) async {
    removedValues.add({'sessionId': sessionId, 'key': key});
    sessionValues[sessionId]?.remove(key);
  }

  @override
  Future<String> createSession([
    Map<String, dynamic> initialData = const {},
  ]) async => 'session';

  @override
  Future<Map<String, dynamic>?> getSession(String sessionId) async => null;

  @override
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> newData,
  ) async {}

  @override
  Future<dynamic> getSessionValue(String sessionId, String key) async =>
      sessionValues[sessionId]?[key];

  @override
  Future<void> destroySession(String sessionId) async {}

  @override
  Future<void> cleanupExpiredSessions() async {}

  @override
  String? getSessionIdFromRequest(HttpRequest request) => null;

  @override
  void setSessionCookie(HttpResponse response, String sessionId) {}

  @override
  void clearSessionCookie(HttpResponse response) {}

  @override
  Future<void> flash(String sessionId, String key, dynamic value) async {}

  @override
  Future<dynamic> getFlashed(String sessionId, String key) async => null;

  @override
  Future<void> flashOldInput(
    String sessionId,
    Map<String, dynamic> inputData,
  ) async {}

  @override
  Future<Map<String, dynamic>?> getOldInput(String sessionId) async => null;

  @override
  Future<bool> hasValidSession(String sessionId) async => true;

  @override
  String get driverName => 'fake';

  @override
  List<String> get driverNames => const ['fake'];

  @override
  Future<void> switchDriver(String driverName) async {}
}

class _FakeUser implements Authenticatable {
  final dynamic id;
  _FakeUser(this.id);

  @override
  dynamic getAuthIdentifier() => id;

  @override
  String getAuthIdentifierName() => 'id';

  @override
  String? getAuthPassword() => null;

  @override
  Map<String, dynamic> toAuthArray() => {'id': id};
}

void main() {
  group('WebGuard session fixation protection', () {
    late _FakeSessionManager sessions;
    late WebGuard guard;

    setUp(() {
      sessions = _FakeSessionManager();

      guard = WebGuard(
        config: KhademAuthConfig(),
        driver: _FakeAuthDriver(),
        providerKey: 'users',
        sessionManager: sessions,
      );
    });

    test('regenerates session id on loginWithSessionId', () async {
      final user = _FakeUser(7);

      final response = await guard.loginWithSessionId(user, 'old_session');

      expect(sessions.regeneratedSessionIds, contains('old_session'));
      expect(response.metadata?['session_id'], equals('old_session_rotated'));
      expect(response.metadata?['session_regenerated'], isTrue);
      expect(
        sessions.sessionValues['old_session_rotated']?['auth_user_id'],
        equals(7),
      );
    });

    test('regenerates session id on logoutWithSessionId', () async {
      await guard.logoutWithSessionId('active_session');

      expect(sessions.regeneratedSessionIds, contains('active_session'));
      expect(
        sessions.removedValues,
        containsAll([
          {'sessionId': 'active_session', 'key': 'auth_user_id'},
          {'sessionId': 'active_session', 'key': 'auth_remember_token'},
        ]),
      );
    });
  });
}

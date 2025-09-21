import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Session Manager
///
/// A clean and solid session management system that integrates with HTTP requests and responses.
/// Supports multiple storage backends and provides a unified interface for session operations.
class SessionManager {
  static const String _sessionCookieName = 'khadem_session';
  static const String _sessionDir = 'storage/sessions';
  static const Duration _defaultLifetime = Duration(hours: 24);

  final Directory _sessionDirectory;
  final Duration _lifetime;

  SessionManager({
    String sessionDir = _sessionDir,
    Duration lifetime = _defaultLifetime,
  }) : _sessionDirectory = Directory(sessionDir),
       _lifetime = lifetime {
    // Ensure session directory exists
    if (!_sessionDirectory.existsSync()) {
      _sessionDirectory.createSync(recursive: true);
    }
  }

  /// Generates a cryptographically secure session ID
  String generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 32);
  }

  /// Creates a new session with optional initial data
  Future<String> createSession([Map<String, dynamic> initialData = const {}]) async {
    final sessionId = generateSessionId();
    final sessionData = {
      '_created': DateTime.now().toIso8601String(),
      '_last_accessed': DateTime.now().toIso8601String(),
      ...initialData,
    };

    await _storeSessionData(sessionId, sessionData);
    return sessionId;
  }

  /// Retrieves session data by ID
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    if (sessionId.isEmpty) return null;

    final data = await _retrieveSessionData(sessionId);
    if (data == null) return null;

    // Check if session has expired
    if (_isSessionExpired(data)) {
      await destroySession(sessionId);
      return null;
    }

    // Update last accessed time
    data['_last_accessed'] = DateTime.now().toIso8601String();
    await _storeSessionData(sessionId, data);

    return data;
  }

  /// Updates session data
  Future<void> updateSession(String sessionId, Map<String, dynamic> data) async {
    if (sessionId.isEmpty) return;

    final existingData = await getSession(sessionId);
    if (existingData == null) return;

    final updatedData = {
      ...existingData,
      ...data,
      '_last_accessed': DateTime.now().toIso8601String(),
    };

    await _storeSessionData(sessionId, updatedData);
  }

  /// Destroys a session
  Future<void> destroySession(String sessionId) async {
    if (sessionId.isEmpty) return;

    final file = File('${_sessionDirectory.path}/$sessionId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Regenerates session ID while preserving data
  Future<String> regenerateSession(String oldSessionId) async {
    final data = await getSession(oldSessionId);
    if (data == null) return createSession();

    await destroySession(oldSessionId);
    return createSession(data);
  }

  /// Cleans up expired sessions
  Future<void> cleanupExpiredSessions() async {
    final dir = _sessionDirectory;
    if (!await dir.exists()) return;

    final files = dir.listSync();
    final now = DateTime.now();

    for (final file in files) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final stat = await file.stat();
          // Remove sessions older than lifetime
          if (now.difference(stat.modified) > _lifetime) {
            await file.delete();
          }
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    }
  }

  /// Gets session ID from request cookies
  String? getSessionIdFromRequest(HttpRequest request) {
    try {
      final cookie = request.cookies.firstWhere(
        (cookie) => cookie.name == _sessionCookieName,
      );
      return cookie.value;
    } catch (e) {
      return null;
    }
  }

  /// Sets session cookie in response
  void setSessionCookie(HttpResponse response, String sessionId, {
    Duration? maxAge,
    bool secure = false,
    bool httpOnly = true,
    String sameSite = 'lax',
  }) {
    final cookie = Cookie(_sessionCookieName, sessionId);
    cookie.maxAge = (maxAge ?? _lifetime).inSeconds;
    cookie.httpOnly = httpOnly;
    cookie.secure = secure;
    cookie.path = '/';

    switch (sameSite.toLowerCase()) {
      case 'strict':
        cookie.sameSite = SameSite.strict;
        break;
      case 'lax':
        cookie.sameSite = SameSite.lax;
        break;
      default:
        // Keep default
        break;
    }

    response.cookies.add(cookie);
  }

  /// Clears session cookie
  void clearSessionCookie(HttpResponse response) {
    final cookie = Cookie(_sessionCookieName, '');
    cookie.maxAge = 0;
    cookie.expires = DateTime.now().subtract(const Duration(seconds: 1));
    cookie.path = '/';
    response.cookies.add(cookie);
  }

  /// Flash old input data to session for form repopulation
  Future<void> flashOldInput(String sessionId, Map<String, dynamic> inputData) async {
    final sessionData = await getSession(sessionId);
    if (sessionData == null) return;

    sessionData['_old_input'] = inputData;
    await _storeSessionData(sessionId, sessionData);
  }

  /// Get and clear flashed old input data
  Future<Map<String, dynamic>?> getOldInput(String sessionId) async {
    final sessionData = await getSession(sessionId);
    if (sessionData == null) return null;

    final oldInput = sessionData['_old_input'] as Map<String, dynamic>?;
    if (oldInput != null) {
      // Clear the old input after retrieving it
      sessionData.remove('_old_input');
      await _storeSessionData(sessionId, sessionData);
    }

    return oldInput;
  }

  /// Checks if session data indicates expiration
  bool _isSessionExpired(Map<String, dynamic> data) {
    final createdStr = data['_created'] as String?;
    if (createdStr == null) return false;

    try {
      final created = DateTime.parse(createdStr);
      return DateTime.now().difference(created) > _lifetime;
    } catch (e) {
      return false;
    }
  }

  /// Stores session data to file
  Future<void> _storeSessionData(String sessionId, Map<String, dynamic> data) async {
    final file = File('${_sessionDirectory.path}/$sessionId.json');
    final jsonData = jsonEncode(data);
    await file.writeAsString(jsonData);
  }

  /// Retrieves session data from file
  Future<Map<String, dynamic>?> _retrieveSessionData(String sessionId) async {
    final file = File('${_sessionDirectory.path}/$sessionId.json');
    if (!await file.exists()) {
      return null;
    }

    try {
      final jsonData = await file.readAsString();
      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      // Invalid session file, remove it
      await file.delete();
      return null;
    }
  }
}

import 'dart:io';

import '../../contracts/session/session_interfaces.dart';
import 'session_cookie_handler.dart';
import 'session_id_generator.dart';
import 'session_validator.dart';

/// Main Session Manager
/// Orchestrates session operations using dependency injection
class SessionManager implements ISessionManager {
  final SessionIdGenerator _idGenerator;
  final SessionCookieHandler _cookieHandler;
  final SessionValidator _validator;
  final ISessionDriverRegistry _driverRegistry;
  final Duration _maxAge;

  String _currentDriverName;

  SessionManager({
    required ISessionDriverRegistry driverRegistry,
    required String driverName,
    SessionIdGenerator? idGenerator,
    SessionCookieHandler? cookieHandler,
    SessionValidator? validator,
    Duration maxAge = const Duration(hours: 24),
  })  : _idGenerator = idGenerator ?? SessionIdGenerator(),
        _cookieHandler = cookieHandler ?? SessionCookieHandler(),
        _validator = validator ?? SessionValidator(),
        _driverRegistry = driverRegistry,
        _maxAge = maxAge,
        _currentDriverName = driverName {
    if (!_driverRegistry.hasDriver(driverName)) {
      throw ArgumentError('Session driver "$driverName" is not registered');
    }
  }

  /// Factory constructor for file-based storage
  factory SessionManager.fileBased({
    String sessionPath = 'storage/sessions',
    Duration maxAge = const Duration(hours: 24),
    SessionCookieHandler? cookieHandler,
  }) {
    // This factory is deprecated. Use dependency injection with registered drivers instead.
    throw UnimplementedError(
      'Use SessionDriverRegistry to register drivers and create SessionManager with dependency injection',
    );
  }

  /// Get the current session driver
  SessionDriver get _currentDriver =>
      _driverRegistry.getDriver(_currentDriverName)!;

  /// Create a new session
  @override
  Future<String> createSession([
    Map<String, dynamic> initialData = const {},
  ]) async {
    final sessionId = _idGenerator.generate();
    final sessionData = _validator.initializeSessionData(initialData);

    await _currentDriver.write(sessionId, sessionData);
    return sessionId;
  }

  /// Get session data
  @override
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    if (sessionId.isEmpty) return null;

    final data = await _currentDriver.read(sessionId);
    if (data == null) return null;

    if (_validator.isExpired(data, _maxAge)) {
      await destroySession(sessionId);
      return null;
    }

    _validator.updateLastAccessed(data);
    await _currentDriver.write(sessionId, data);

    return data;
  }

  /// Update session data
  @override
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> newData,
  ) async {
    if (sessionId.isEmpty) return;

    final existingData = await getSession(sessionId);
    if (existingData == null) return;

    final updatedData = {
      ...existingData,
      'data': {
        ...(existingData['data'] as Map<String, dynamic>),
        ...newData,
      },
    };
    _validator.updateLastAccessed(updatedData);

    await _currentDriver.write(sessionId, updatedData);
  }

  /// Get session value
  @override
  Future<dynamic> getSessionValue(String sessionId, String key) async {
    final data = await getSession(sessionId);
    if (data == null) return null;

    final sessionData = data['data'] as Map<String, dynamic>;
    return sessionData[key];
  }

  /// Set session value
  @override
  Future<void> setSessionValue(
    String sessionId,
    String key,
    dynamic value,
  ) async {
    final data = await getSession(sessionId);
    if (data == null) return;

    final sessionData =
        Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
    sessionData[key] = value;

    final updatedData = {
      ...data,
      'data': sessionData,
    };
    _validator.updateLastAccessed(updatedData);

    await _currentDriver.write(sessionId, updatedData);
  }

  /// Remove session value
  @override
  Future<void> removeSessionValue(String sessionId, String key) async {
    final data = await getSession(sessionId);
    if (data == null) return;

    final sessionData =
        Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
    sessionData.remove(key);

    final updatedData = {
      ...data,
      'data': sessionData,
    };
    _validator.updateLastAccessed(updatedData);

    await _currentDriver.write(sessionId, updatedData);
  }

  /// Destroy session
  @override
  Future<void> destroySession(String sessionId) async {
    if (sessionId.isEmpty) return;
    await _currentDriver.delete(sessionId);
  }

  /// Regenerate session ID
  @override
  Future<String> regenerateSession(String oldSessionId) async {
    final data = await getSession(oldSessionId);
    if (data == null) return createSession();

    await destroySession(oldSessionId);
    return createSession(data['data'] as Map<String, dynamic>);
  }

  /// Cleanup expired sessions
  @override
  Future<void> cleanupExpiredSessions() async {
    await _currentDriver.cleanup(_maxAge);
  }

  /// Get session ID from request
  @override
  String? getSessionIdFromRequest(HttpRequest request) {
    return _cookieHandler.getSessionIdFromRequest(request);
  }

  /// Set session cookie
  @override
  void setSessionCookie(HttpResponse response, String sessionId) {
    _cookieHandler.setSessionCookie(response, sessionId);
  }

  /// Clear session cookie
  @override
  void clearSessionCookie(HttpResponse response) {
    _cookieHandler.clearSessionCookie(response);
  }

  /// Flash data to session
  @override
  Future<void> flash(String sessionId, String key, dynamic value) async {
    final data = await getSession(sessionId);
    if (data == null) return;

    data['_flash'] ??= <String, dynamic>{};
    (data['_flash'] as Map<String, dynamic>)[key] = value;
    await _currentDriver.write(sessionId, data);
  }

  /// Get flashed data (and clear it)
  @override
  Future<dynamic> getFlashed(String sessionId, String key) async {
    final data = await getSession(sessionId);
    if (data == null) return null;

    final flash = data['_flash'] as Map<String, dynamic>?;
    if (flash == null) return null;

    final value = flash[key];
    flash.remove(key);

    // Clean up empty flash data
    if (flash.isEmpty) {
      data.remove('_flash');
    }

    await _currentDriver.write(sessionId, data);
    return value;
  }

  /// Flash old input data to session for form repopulation
  @override
  Future<void> flashOldInput(
    String sessionId,
    Map<String, dynamic> inputData,
  ) async {
    await flash(sessionId, 'old_input', inputData);
  }

  /// Get and clear flashed old input data
  @override
  Future<Map<String, dynamic>?> getOldInput(String sessionId) async {
    return await getFlashed(sessionId, 'old_input') as Map<String, dynamic>?;
  }

  /// Check if session exists and is valid
  @override
  Future<bool> hasValidSession(String sessionId) async {
    final data = await _currentDriver.read(sessionId);
    return data != null && !_validator.isExpired(data, _maxAge);
  }

  /// Get current driver name
  @override
  String get driverName => _currentDriverName;

  /// Get all available driver names
  @override
  List<String> get driverNames => _driverRegistry.getDriverNames();

  /// Switch to a different driver
  @override
  Future<void> switchDriver(String driverName) async {
    if (!_driverRegistry.hasDriver(driverName)) {
      throw ArgumentError('Session driver "$driverName" is not registered');
    }
    _currentDriverName = driverName;
  }
}

import 'dart:io';

/// Session storage driver interface.
/// Defines the contract for session storage implementations.
abstract class SessionDriver {
  /// Store session data
  Future<void> write(String sessionId, Map<String, dynamic> data);

  /// Retrieve session data
  Future<Map<String, dynamic>?> read(String sessionId);

  /// Delete session data
  Future<void> delete(String sessionId);

  /// Clean up expired sessions
  Future<void> cleanup(Duration maxAge);

  /// Check if driver is connected/ready
  Future<bool> isConnected();
}

/// Session manager interface.
/// Defines the contract for session management operations.
abstract class ISessionManager {
  /// Create a new session
  Future<String> createSession([
    Map<String, dynamic> initialData = const {},
  ]);

  /// Get session data
  Future<Map<String, dynamic>?> getSession(String sessionId);

  /// Update session data
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> newData,
  );

  /// Get session value
  Future<dynamic> getSessionValue(String sessionId, String key);

  /// Set session value
  Future<void> setSessionValue(String sessionId, String key, dynamic value);

  /// Remove session value
  Future<void> removeSessionValue(String sessionId, String key);

  /// Destroy session
  Future<void> destroySession(String sessionId);

  /// Regenerate session ID
  Future<String> regenerateSession(String oldSessionId);

  /// Cleanup expired sessions
  Future<void> cleanupExpiredSessions();

  /// Get session ID from request
  String? getSessionIdFromRequest(HttpRequest request);

  /// Set session cookie
  void setSessionCookie(HttpResponse response, String sessionId);

  /// Clear session cookie
  void clearSessionCookie(HttpResponse response);

  /// Flash data to session
  Future<void> flash(String sessionId, String key, dynamic value);

  /// Get flashed data (and clear it)
  Future<dynamic> getFlashed(String sessionId, String key);

  /// Flash old input data to session for form repopulation
  Future<void> flashOldInput(String sessionId, Map<String, dynamic> inputData);

  /// Get and clear flashed old input data
  Future<Map<String, dynamic>?> getOldInput(String sessionId);

  /// Check if session exists and is valid
  Future<bool> hasValidSession(String sessionId);

  /// Get current driver name
  String get driverName;

  /// Get all available driver names
  List<String> get driverNames;

  /// Switch to a different driver
  Future<void> switchDriver(String driverName);
}

/// Session driver registry interface.
/// Defines the contract for managing session drivers.
abstract class ISessionDriverRegistry {
  /// Registers a session driver with the given name.
  void registerDriver(String name, SessionDriver driver);

  /// Gets a session driver by name.
  SessionDriver? getDriver(String name);

  /// Gets all registered driver names.
  List<String> getDriverNames();

  /// Checks if a driver is registered.
  bool hasDriver(String name);

  /// Sets the default session driver.
  void setDefaultDriver(String name);

  /// Gets the current default driver.
  SessionDriver getDefaultDriver();

  /// Gets the name of the current default driver.
  String getDefaultDriverName();

  /// Removes a driver from the registry.
  void removeDriver(String name);
}

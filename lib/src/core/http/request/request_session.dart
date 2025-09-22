import 'dart:io';

/// Manages HTTP sessions for the Khadem framework.
///
/// This class provides a clean interface for session management,
/// wrapping the raw HttpSession with additional utilities and security features.
class RequestSession {
  final HttpRequest _request;

  RequestSession(this._request);

  HttpSession get _session => _request.session;

  /// Gets the session ID.
  String get sessionId => _session.id;

  /// Gets all session keys.
  Iterable<dynamic> get sessionKeys => _session.keys;

  /// Checks if the session is empty.
  bool get isSessionEmpty => _session.isEmpty;

  /// Gets the number of items in the session.
  int get sessionLength => _session.length;

  /// Destroys the current session.
  void destroy() {
    _session.destroy();
  }

  /// Gets a value from the session by key.
  dynamic get(String key) {
    touch();
    return _session[key];
  }

  /// Sets a value in the session.
  void set(String key, dynamic value) {
    touch();
    _session[key] = value;
  }

  /// Checks if a key exists in the session.
  bool has(String key) {
    touch();
    return _session.containsKey(key);
  }

  /// Removes a key from the session.
  void remove(String key) {
    touch();
    _session.remove(key);
  }

  /// Clears all session data.
  void clear() {
    touch();
    _session.clear();
  }

  /// Sets multiple values in the session at once.
  void setMultiple(Map<String, dynamic> data) {
    touch();
    data.forEach((key, value) => _session[key] = value);
  }

  /// Gets a typed value from the session, with optional default.
  T? getTyped<T>(String key, [T? defaultValue]) {
    touch();
    final value = _session[key];
    return value is T ? value : defaultValue;
  }

  /// Flashes a value to the session (temporary, removed after next access).
  void flash(String key, dynamic value) {
    touch();
    final Map<String, dynamic> flashData =
        _session['flash'] ?? <String, dynamic>{};
    flashData[key] = value;
    _session['flash'] = flashData;
  }

  /// Retrieves and removes a flashed value from the session.
  dynamic pull(String key) {
    touch();
    final value = _session[key];
    if (value != null) {
      _session.remove(key);
    }
    return value;
  }

  /// Regenerates the session ID for security.
  void regenerateId() {
    final sessionData = Map<String, dynamic>.from(_session);
    // Preserve important metadata
    final timeout = sessionData['timeout_seconds'];

    _session.destroy();
    // After destroy, accessing _session creates a new session

    // Restore data but update creation time for security
    sessionData.forEach((key, value) {
      if (key != 'created_at') {
        // Don't restore old creation time
        _session[key] = value;
      }
    });

    // Set new creation time
    _session['created_at'] = DateTime.now().toIso8601String();
    // Preserve timeout if it was set
    if (timeout != null) {
      _session['timeout_seconds'] = timeout;
    }
  }

  /// Gets all flashed data and clears them.
  Map<String, dynamic> getFlashedData() {
    touch();
    final flashData = _session['flash'] as Map<String, dynamic>? ?? {};
    _session.remove('flash');
    return flashData;
  }

  /// Checks if the session has any flashed data.
  bool hasFlashedData() {
    touch();
    final flashData = _session['flash'] as Map<String, dynamic>?;
    return flashData != null && flashData.isNotEmpty;
  }

  /// Sets the session timeout.
  void setTimeout(Duration timeout) {
    touch();
    _session['timeout_seconds'] = timeout.inSeconds;
    _session['created_at'] = DateTime.now().toIso8601String();
  }

  /// Gets the session timeout if set.
  Duration? getTimeout() {
    final timeoutSeconds = _session['timeout_seconds'];
    if (timeoutSeconds is int) {
      return Duration(seconds: timeoutSeconds);
    }
    return null;
  }

  /// Validates the session based on timeout and other security checks.
  bool isValid() {
    // Check if session has been manually invalidated
    if (isInvalidated()) {
      return false;
    }

    // Check if session has expired
    if (isExpired()) {
      return false;
    }

    // Check if session was created (basic integrity check)
    final createdAt = _session['created_at'];
    if (createdAt == null) {
      return false;
    }

    // Additional validation can be added here
    // e.g., check IP address consistency, user agent, etc.

    return true;
  }

  /// Checks if the session has expired based on timeout.
  bool isExpired() {
    final timeout = getTimeout();
    if (timeout == null) {
      return false; // No timeout set, never expires
    }

    final createdAtStr = _session['created_at'];
    if (createdAtStr == null) {
      return true; // No creation time, consider expired
    }

    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) {
      return true; // Invalid creation time
    }

    final now = DateTime.now();
    return now.difference(createdAt) > timeout;
  }

  /// Gets the session age.
  Duration getAge() {
    final createdAtStr = _session['created_at'];
    if (createdAtStr == null) {
      return Duration.zero;
    }

    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) {
      return Duration.zero;
    }

    return DateTime.now().difference(createdAt);
  }

  /// Gets the remaining time before session expires.
  Duration? getTimeUntilExpiration() {
    final timeout = getTimeout();
    if (timeout == null) {
      return null; // No timeout set
    }

    final age = getAge();
    if (age > timeout) {
      return Duration.zero; // Already expired
    }

    return timeout - age;
  }

  /// Touches the session to update last access time.
  void touch() {
    _session['last_access'] = DateTime.now().toIso8601String();
  }

  /// Gets the last access time of the session.
  DateTime? getLastAccess() {
    final lastAccess = _session['last_access'];
    if (lastAccess is String) {
      return DateTime.tryParse(lastAccess);
    }
    return null;
  }

  /// Gets the session creation time.
  DateTime? getCreatedAt() {
    final createdAt = _session['created_at'];
    if (createdAt is String) {
      return DateTime.tryParse(createdAt);
    }
    return null;
  }

  /// Checks if the session should be regenerated (security best practice).
  bool shouldRegenerate({Duration maxAge = const Duration(hours: 1)}) {
    final createdAt = getCreatedAt();
    if (createdAt == null) {
      return true; // Regenerate if no creation time
    }

    return DateTime.now().difference(createdAt) > maxAge;
  }

  /// Forces session invalidation.
  void invalidate() {
    _session['invalidated'] = true;
    _session['invalidated_at'] = DateTime.now().toIso8601String();
  }

  /// Checks if the session has been invalidated.
  bool isInvalidated() {
    return _session['invalidated'] == true;
  }

  /// Gets session statistics.
  Map<String, dynamic> getStats() {
    return {
      'id': sessionId,
      'is_empty': isSessionEmpty,
      'length': sessionLength,
      'age': getAge().inSeconds,
      'is_expired': isExpired(),
      'is_valid': isValid(),
      'time_until_expiration': getTimeUntilExpiration()?.inSeconds,
      'created_at': getCreatedAt()?.toIso8601String(),
      'last_access': getLastAccess()?.toIso8601String(),
      'has_timeout': getTimeout() != null,
      'timeout_seconds': getTimeout()?.inSeconds,
    };
  }

  /// Cleans up expired flash data and performs maintenance.
  void cleanup() {
    // Remove old flash data if it exists
    if (_session.containsKey('flash')) {
      final flashData = _session['flash'] as Map<String, dynamic>?;
      if (flashData == null || flashData.isEmpty) {
        _session.remove('flash');
      }
    }

    // Additional cleanup can be added here
    // e.g., remove temporary data, compress session data, etc.
  }

  /// Gets all session data as a map (excluding internal metadata).
  Map<String, dynamic> getAllData() {
    final data = <String, dynamic>{};
    for (final key in _session.keys) {
      if (!key.toString().startsWith('_') &&
          ![
            'created_at',
            'last_access',
            'timeout_seconds',
            'invalidated',
            'invalidated_at',
          ].contains(key)) {
        data[key] = _session[key];
      }
    }
    return data;
  }

  /// Checks if the session is about to expire within the given duration.
  bool isExpiringSoon([Duration within = const Duration(minutes: 5)]) {
    final timeUntilExpiration = getTimeUntilExpiration();
    if (timeUntilExpiration == null) {
      return false; // No timeout set
    }
    return timeUntilExpiration <= within && timeUntilExpiration > Duration.zero;
  }
}

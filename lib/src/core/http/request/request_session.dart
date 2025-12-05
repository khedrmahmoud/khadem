import 'dart:io';

/// Manages HTTP sessions for the Khadem framework.
///
/// This class provides a clean interface for session management,
/// wrapping the raw HttpSession with additional utilities and security features.
class RequestSession {
  final HttpRequest _request;

  RequestSession(this._request) {
    _rotateFlash();
  }

  HttpSession get _session => _request.session;

  /// Rotates flash data (new -> old).
  void _rotateFlash() {
    // If we already rotated in this session (e.g. multiple Request objects), skip?
    // HttpSession is shared. We need a flag or check if we are the first.
    // But Request is usually one per request.
    // However, if we access session, we lock it? No, Dart HttpSession is simple.
    
    // We need to be careful not to rotate multiple times if RequestSession is created multiple times.
    // But Request creates it once.
    
    if (_session.containsKey('_flash_new')) {
      _session['_flash_old'] = _session['_flash_new'];
    } else {
      _session['_flash_old'] = <String, dynamic>{};
    }
    _session['_flash_new'] = <String, dynamic>{};
  }

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
  dynamic get(String key, [dynamic defaultValue]) {
    touch();
    if (_session.containsKey(key)) {
      return _session[key];
    }
    // Check flash old
    final flashOld = _session['_flash_old'];
    if (flashOld is Map && flashOld.containsKey(key)) {
      return flashOld[key];
    }
    return defaultValue;
  }

  /// Sets a value in the session.
  void set(String key, dynamic value) {
    touch();
    _session[key] = value;
  }

  /// Alias for set.
  void put(String key, dynamic value) => set(key, value);

  /// Checks if a key exists in the session.
  bool has(String key) {
    touch();
    if (_session.containsKey(key)) return true;
    final flashOld = _session['_flash_old'];
    if (flashOld is Map && flashOld.containsKey(key)) return true;
    return false;
  }

  /// Removes a key from the session.
  void remove(String key) {
    touch();
    _session.remove(key);
  }

  /// Alias for remove.
  void forget(String key) => remove(key);

  /// Clears all session data.
  void clear() {
    touch();
    _session.clear();
  }

  /// Alias for clear.
  void flush() => clear();

  /// Sets multiple values in the session at once.
  void setMultiple(Map<String, dynamic> data) {
    touch();
    data.forEach((key, value) => _session[key] = value);
  }

  /// Gets a typed value from the session, with optional default.
  T? getTyped<T>(String key, [T? defaultValue]) {
    final value = get(key);
    return value is T ? value : defaultValue;
  }

  /// Flashes a value to the session (temporary, removed after next access).
  void flash(String key, dynamic value) {
    touch();
    final flashNew = _session['_flash_new'];
    if (flashNew is Map) {
      flashNew[key] = value;
    } else {
      _session['_flash_new'] = {key: value};
    }
  }

  /// Retrieves and removes a value from the session.
  dynamic pull(String key, [dynamic defaultValue]) {
    touch();
    final value = get(key, defaultValue);
    remove(key);
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
      if (key != 'created_at' && !key.toString().startsWith('_flash')) {
        // Don't restore old creation time or flash data (handled separately?)
        // Actually we should restore flash data
        _session[key] = value;
      }
    });
    
    // Restore flash
    if (sessionData.containsKey('_flash_new')) {
        _session['_flash_new'] = sessionData['_flash_new'];
    }
    if (sessionData.containsKey('_flash_old')) {
        _session['_flash_old'] = sessionData['_flash_old'];
    }

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
    final flashOld = _session['_flash_old'];
    if (flashOld is Map) {
        return Map<String, dynamic>.from(flashOld);
    }
    return {};
  }

  /// Checks if the session has any flashed data.
  bool hasFlashedData() {
    touch();
    final flashOld = _session['_flash_old'];
    return flashOld is Map && flashOld.isNotEmpty;
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
    // Remove old flash data
    _session.remove('_flash_old');
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

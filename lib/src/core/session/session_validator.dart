/// Session Data Validator
/// Handles session data validation and expiration checks
class SessionValidator {
  /// Check if session data indicates expiration
  bool isExpired(Map<String, dynamic> data, Duration maxAge) {
    final lastActivityStr = data['last_activity'] as String?;
    if (lastActivityStr == null) return false;

    try {
      final lastActivity = DateTime.parse(lastActivityStr);
      return DateTime.now().difference(lastActivity) > maxAge;
    } catch (e) {
      return false;
    }
  }

  /// Update last accessed timestamp
  void updateLastAccessed(Map<String, dynamic> data) {
    data['last_activity'] = DateTime.now().toIso8601String();
  }

  /// Initialize session data
  Map<String, dynamic> initializeSessionData([
    Map<String, dynamic> initialData = const {},
  ]) {
    return {
      'created_at': DateTime.now().toIso8601String(),
      'last_activity': DateTime.now().toIso8601String(),
      'data': initialData,
    };
  }
}

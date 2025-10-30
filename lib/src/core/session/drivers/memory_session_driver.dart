import '../../../contracts/session/session_interfaces.dart';

/// Memory-based session storage implementation.
/// Stores session data in memory (not persistent across restarts).
class MemorySessionDriver implements SessionDriver {
  final Map<String, Map<String, dynamic>> _sessions = {};

  @override
  Future<void> write(String sessionId, Map<String, dynamic> data) async {
    _sessions[sessionId] = Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>?> read(String sessionId) async {
    return _sessions[sessionId] != null
        ? Map<String, dynamic>.from(_sessions[sessionId]!)
        : null;
  }

  @override
  Future<void> delete(String sessionId) async {
    _sessions.remove(sessionId);
  }

  @override
  Future<void> cleanup(Duration maxAge) async {
    final now = DateTime.now();
    final expiredSessions = <String>[];

    for (final entry in _sessions.entries) {
      final data = entry.value;
      final lastActivityStr = data['last_activity'] as String?;
      if (lastActivityStr != null) {
        try {
          final lastActivity = DateTime.parse(lastActivityStr);
          if (now.difference(lastActivity) > maxAge) {
            expiredSessions.add(entry.key);
          }
        } catch (e) {
          // Invalid timestamp, consider expired
          expiredSessions.add(entry.key);
        }
      }
    }

    for (final sessionId in expiredSessions) {
      _sessions.remove(sessionId);
    }
  }

  @override
  Future<bool> isConnected() async {
    return true; // Memory is always available
  }

  /// Get the number of active sessions (for debugging/testing)
  int get sessionCount => _sessions.length;

  /// Clear all sessions (for testing)
  void clearAll() {
    _sessions.clear();
  }
}

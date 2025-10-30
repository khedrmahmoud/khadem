/// Token management service interface
///
/// This interface abstracts token storage, retrieval, and management
/// operations. It provides a clean separation between token business
/// logic and data persistence.
abstract class TokenService {
  /// Stores a token with associated metadata
  ///
  /// [tokenData] Token data including token string, user ID, type, etc.
  /// Returns the stored token data
  Future<Map<String, dynamic>> storeToken(Map<String, dynamic> tokenData);

  /// Finds a token by token string
  ///
  /// [token] The token string to search for
  /// Returns token data if found, null otherwise
  Future<Map<String, dynamic>?> findToken(String token);

  /// Finds all tokens for a specific user
  ///
  /// [userId] The user ID to search for
  /// [guard] Optional guard name to filter by
  /// Returns list of token data for the user
  Future<List<Map<String, dynamic>>> findTokensByUser(
    dynamic userId, [
    String? guard,
  ]);

  /// Deletes a specific token
  ///
  /// [token] The token string to delete
  /// Returns number of deleted records
  Future<int> deleteToken(String token);

  /// Deletes all tokens for a user
  ///
  /// [userId] The user ID
  /// [guard] Optional guard name to filter by
  /// Returns number of deleted records
  Future<int> deleteUserTokens(
    dynamic userId, {
    String? guard,
    Map<String, dynamic>? filter,
  });

  /// Finds tokens by session ID
  ///
  /// [sessionId] The session ID to search for
  /// [guard] Optional guard name to filter by
  /// [type] Optional token type to filter by (e.g., 'refresh')
  /// Returns list of token data for the session
  Future<List<Map<String, dynamic>>> findTokensBySession(
    String sessionId, [
    String? guard,
    String? type,
  ]);

  /// Invalidates a specific session
  ///
  /// [sessionId] The session ID to invalidate
  /// [guard] Optional guard name to filter by
  /// Returns number of invalidated tokens
  Future<int> invalidateSession(String sessionId, [String? guard]);

  /// Cleans up expired tokens
  ///
  /// Returns number of cleaned up tokens
  Future<int> cleanupExpiredTokens();

  /// Blacklists a token (for stateless tokens like JWT)
  ///
  /// [tokenData] Blacklist data including token, expiry, etc.
  /// Returns the blacklist record
  Future<Map<String, dynamic>> blacklistToken(Map<String, dynamic> tokenData);

  /// Checks if a token is blacklisted
  ///
  /// [token] The token to check
  /// Returns true if blacklisted, false otherwise
  Future<bool> isTokenBlacklisted(String token);
}

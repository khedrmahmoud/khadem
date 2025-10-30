/// Repository interface for authentication data access
///
/// This interface defines the contract for accessing user and token data
/// in the authentication system. It follows the Repository pattern to
/// abstract data access operations and make them testable.
abstract class AuthRepository {
  /// Finds a user by credentials
  ///
  /// [credentials] Map containing login credentials
  /// [fields] List of fields to check (email, username, etc.)
  /// [table] The table name to search in
  /// Returns the user record if found, null otherwise
  Future<Map<String, dynamic>?> findUserByCredentials(
    Map<String, dynamic> credentials,
    List<String> fields,
    String table,
  );

  /// Finds a user by ID
  ///
  /// [id] The user ID
  /// [table] The table name
  /// [primaryKey] The primary key field name
  /// Returns the user record if found, null otherwise
  Future<Map<String, dynamic>?> findUserById(
    dynamic id,
    String table,
    String primaryKey,
  );

  /// Stores a token in the database
  ///
  /// [tokenData] Map containing token information
  /// Returns the stored token record
  Future<Map<String, dynamic>> storeToken(Map<String, dynamic> tokenData);

  /// Finds a token record
  ///
  /// [token] The token string
  /// Returns the token record if found, null otherwise
  Future<Map<String, dynamic>?> findToken(String token);

  /// Deletes a token
  ///
  /// [token] The token string to delete
  /// Returns the number of affected rows
  Future<int> deleteToken(String token);

  /// Deletes all tokens for a user
  ///
  /// [userId] The user ID
  /// [guard] Optional guard name filter
  /// [filter] Optional metadata to filter tokens
  /// Returns the number of affected rows
  Future<int> deleteUserTokens(dynamic userId,
      {String? guard, Map<String, dynamic>? filter,});

  /// Finds all tokens for a user
  ///
  /// [userId] The user ID
  /// [guard] Optional guard name filter
  /// Returns a list of token records
  Future<List<Map<String, dynamic>>> findTokensByUser(dynamic userId,
      [String? guard,]);

  /// Cleans up expired tokens
  ///
  /// Returns the number of deleted tokens
  Future<int> cleanupExpiredTokens();
}

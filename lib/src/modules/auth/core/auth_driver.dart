/// Abstract authentication driver interface
///
/// This interface defines the contract for authentication drivers in the Khadem framework.
/// Different authentication methods (JWT, Token, OAuth, etc.) should implement this interface
/// to provide consistent authentication functionality.
///
/// Example implementation:
/// ```dart
/// class CustomAuthDriver implements AuthDriver {
///   @override
///   Future<Map<String, dynamic>> attemptLogin(Map<String, dynamic> credentials) async {
///     // Custom login logic
///     return {'user': userData, 'token': tokenData};
///   }
///
///   @override
///   Future<Map<String, dynamic>> verifyToken(String token) async {
///     // Custom token verification logic
///     return userData;
///   }
///
///   @override
///   Future<void> logout(String token) async {
///     // Custom logout logic
///   }
///
///   @override
///   Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
///     // Custom token refresh logic
///     return {'access_token': newToken, 'expires_in': 3600};
///   }
/// }
/// ```
abstract class AuthDriver {
  /// Attempts to authenticate a user with the provided credentials
  ///
  /// [credentials] A map containing authentication credentials (e.g., email, password)
  /// Returns a map containing user data and authentication tokens
  /// Throws [AuthException] if authentication fails
  Future<Map<String, dynamic>> attemptLogin(Map<String, dynamic> credentials);

  /// Verifies the validity of an authentication token
  ///
  /// [token] The authentication token to verify
  /// Returns the user data associated with the token
  /// Throws [AuthException] if token is invalid or expired
  Future<Map<String, dynamic>> verifyToken(String token);

  /// Logs out a user by invalidating their authentication token
  ///
  /// [token] The authentication token to invalidate
  /// Throws [AuthException] if logout fails
  Future<void> logout(String token);

  /// Refreshes an access token using a refresh token
  ///
  /// [refreshToken] The refresh token to use for generating a new access token
  /// Returns a new access token data
  /// Throws [AuthException] if refresh token is invalid or expired
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken);
}

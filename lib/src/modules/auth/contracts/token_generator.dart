/// Token generator interface for creating secure tokens
///
/// This interface defines the contract for token generation in the
/// authentication system. It allows for different token generation
/// strategies while maintaining consistency.
abstract class TokenGenerator {
  /// Generates a secure token
  ///
  /// [length] The desired token length
  /// [prefix] Optional prefix for the token
  /// Returns a secure token string
  String generateToken({int length = 64, String? prefix});

  /// Generates a refresh token
  ///
  /// [length] The desired token length
  /// Returns a secure refresh token string
  String generateRefreshToken({int length = 64});

  /// Validates token format
  ///
  /// [token] The token to validate
  /// Returns true if token format is valid
  bool isValidTokenFormat(String token);
}

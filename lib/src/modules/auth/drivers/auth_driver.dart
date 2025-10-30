import '../contracts/authenticatable.dart';
import '../core/auth_response.dart';
import '../factories/token_invalidation_strategy_factory.dart';

/// Authentication driver interface
///
/// Drivers handle the low-level token operations for different
/// authentication methods (JWT, Token, OAuth, etc.). They are
/// used by guards to perform authentication operations.
abstract class AuthDriver {
  /// Attempts to authenticate a user with credentials
  ///
  /// [credentials] User login credentials
  /// [user] The user to authenticate
  /// Returns authentication response with tokens
  Future<AuthResponse> authenticate(
    Map<String, dynamic> credentials,
    Authenticatable user,
  );

  /// Verifies an authentication token
  ///
  /// [token] The token to verify
  /// Returns the user associated with the token
  Future<Authenticatable> verifyToken(String token);

  /// Generates tokens for a user
  ///
  /// [user] The user to generate tokens for
  /// Returns authentication response with tokens
  Future<AuthResponse> generateTokens(Authenticatable user);

  /// Refreshes an access token
  ///
  /// [refreshToken] The refresh token
  /// Returns new authentication response
  Future<AuthResponse> refreshToken(String refreshToken);

  /// Invalidates a token (single device logout)
  ///
  /// [token] The token to invalidate
  ///
  /// For JWT drivers: Blacklists access token and invalidates associated refresh token
  /// For Token drivers: Deletes the access token
  Future<void> invalidateToken(String token);

  /// Invalidates all tokens for a user (logout from all devices)
  ///
  /// [token] Any valid token for the user (access or refresh)
  /// This will invalidate all sessions across all devices
  Future<void> logoutFromAllDevices(String token);

  /// Invalidates tokens using a specific logout strategy
  ///
  /// [token] The token to use for context
  /// [logoutType] The type of logout strategy to use
  Future<void> invalidateTokenWithStrategy(String token, LogoutType logoutType);

  /// Validates token format
  ///
  /// [token] The token to validate
  /// Returns true if token format is valid
  bool validateTokenFormat(String token);
}

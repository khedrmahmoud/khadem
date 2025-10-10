/// Token invalidation strategy interface
///
/// This interface defines different strategies for invalidating tokens
/// during logout operations. It follows the Strategy pattern to provide
/// flexible logout behaviors.
abstract class TokenInvalidationStrategy {
  /// Invalidates tokens according to the strategy
  ///
  /// [context] Context containing necessary information for invalidation
  /// This could include access token, refresh token, user ID, etc.
  Future<void> invalidateTokens(TokenInvalidationContext context);

  /// Gets a description of what this strategy does
  String get description;
}

/// Context object containing data needed for token invalidation
class TokenInvalidationContext {
  /// The access token to invalidate
  final String? accessToken;

  /// The refresh token to invalidate
  final String? refreshToken;

  /// The user ID associated with the tokens
  final dynamic userId;

  /// The guard/provider key
  final String guard;

  /// Additional token payload (for JWT tokens)
  final Map<String, dynamic>? tokenPayload;

  /// Token expiry timestamp (for JWT tokens)
  final int? tokenExpiry;

  /// Any additional metadata
  final Map<String, dynamic>? metadata;

  const TokenInvalidationContext({
    required this.guard, this.accessToken,
    this.refreshToken,
    this.userId,
    this.tokenPayload,
    this.tokenExpiry,
    this.metadata,
  });

  /// Creates context from an access token and optional refresh token
  factory TokenInvalidationContext.fromTokens({
    required dynamic userId, required String guard, String? accessToken,
    String? refreshToken,
    Map<String, dynamic>? tokenPayload,
    int? tokenExpiry,
    Map<String, dynamic>? metadata,
  }) {
    return TokenInvalidationContext(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      guard: guard,
      tokenPayload: tokenPayload,
      tokenExpiry: tokenExpiry,
      metadata: metadata,
    );
  }
}
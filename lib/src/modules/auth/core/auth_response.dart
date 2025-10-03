import 'package:khadem/khadem.dart';

/// Unified authentication response
///
/// This class provides a standardized format for authentication responses
/// across all guards and drivers. It ensures consistent API responses
/// and makes it easier to work with authentication data.
///
/// Features:
/// - Standardized response format
/// - Type-safe access to response data
/// - Support for different token types
/// - User data encapsulation
/// - Easy serialization
class AuthResponse {
  /// The authenticated user data
  final Map<String, dynamic> user;

  /// The access token
  final String? accessToken;

  /// The refresh token (optional)
  final String? refreshToken;

  /// The token type (e.g., 'Bearer')
  final String tokenType;

  /// Access token expiration time in seconds
  final int? expiresIn;

  /// Refresh token expiration time in seconds
  final int? refreshExpiresIn;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Creates an authentication response
  AuthResponse({
    required this.user,
    this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.refreshExpiresIn,
    this.metadata,
  });

  /// Creates a response from a map
  ///
  /// [data] The response data map
  factory AuthResponse.fromJson(Map<String, dynamic> data) {
    return AuthResponse(
      user: data['user'] as Map<String, dynamic>,
      accessToken: data['access_token'] as String?,
      refreshToken: data['refresh_token'] as String?,
      tokenType: data['token_type'] as String? ?? 'Bearer',
      expiresIn: data['expires_in'] as int?,
      refreshExpiresIn: data['refresh_expires_in'] as int?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts the response to a map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user': user..remove('password'),
      'token_type': tokenType,
    };

    if (accessToken != null) map['access_token'] = accessToken;
    if (refreshToken != null) map['refresh_token'] = refreshToken;
    if (expiresIn != null) map['expires_in'] = expiresIn;
    if (refreshExpiresIn != null) map['refresh_expires_in'] = refreshExpiresIn;
    if (metadata != null) map['metadata'] = metadata;

    return map;
  }

  Map<String, dynamic> toJson() => jsonSafe(toMap()).cast<String, dynamic>();

  /// Creates a token-only response (for refresh operations)
  factory AuthResponse.tokenOnly({
    required String accessToken,
    String? refreshToken,
    String tokenType = 'Bearer',
    int? expiresIn,
    int? refreshExpiresIn,
  }) {
    return AuthResponse(
      user: {},
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      refreshExpiresIn: refreshExpiresIn,
    );
  }

  /// Creates a user-only response (for stateless authentication)
  factory AuthResponse.userOnly(Map<String, dynamic> user) {
    return AuthResponse(
      user: user,
    );
  }

  /// Checks if the response contains tokens
  bool get hasTokens => accessToken != null || refreshToken != null;

  /// Checks if the response contains user data
  bool get hasUser => user.isNotEmpty;

  /// Gets the authorization header value
  String? get authorizationHeader {
    if (accessToken == null) return null;
    return '$tokenType $accessToken';
  }

  @override
  String toString() {
    return 'AuthResponse(user: ${user.keys.join(', ')}, hasTokens: $hasTokens)';
  }
}

import '../lib/src/modules/auth/services/jwt_auth_service.dart';
import '../lib/src/modules/auth/services/token_auth_service.dart';

/// Example demonstrating the enhanced refreshAccessToken functionality
///
/// This example shows how to use the improved token refresh mechanism
/// that generates both new access and refresh tokens for better security.

void main() async {
  // Example with JWT Auth Service
  await demonstrateJWTRefresh();

  // Example with Token Auth Service
  await demonstrateTokenRefresh();
}

/// Demonstrates JWT token refresh functionality
Future<void> demonstrateJWTRefresh() async {
  print('=== JWT Token Refresh Example ===\n');

  // Create JWT auth service (in real app, this would be injected)
  final jwtService = EnhancedJWTAuthService.create('users');

  try {
    // Simulate login to get initial tokens
    print('1. User logs in...');
    final loginResult = await jwtService.attemptLogin({
      'email': 'user@example.com',
      'password': 'password123',
    });

    final tokens = loginResult['token'] as Map<String, dynamic>;
    print('   Access Token: ${tokens['access_token']}');
    print('   Refresh Token: ${tokens['refresh_token']}');
    print('   Expires In: ${tokens['expires_in']} seconds\n');

    // Simulate token refresh after some time
    print('2. Refreshing tokens...');
    final refreshResult = await jwtService.refreshAccessToken(
      tokens['refresh_token'] as String,
    );

    print('   New Access Token: ${refreshResult['access_token']}');
    print('   New Refresh Token: ${refreshResult['refresh_token']}');
    print('   New Expires In: ${refreshResult['expires_in']} seconds');
    print(
      '   Refresh Expires In: ${refreshResult['refresh_expires_in']} seconds\n',
    );

    // The old refresh token is now invalid for security
    print('3. Old refresh token is automatically invalidated for security\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Demonstrates simple token refresh functionality
Future<void> demonstrateTokenRefresh() async {
  print('=== Simple Token Refresh Example ===\n');

  // Create token auth service (in real app, this would be injected)
  final tokenService = EnhancedTokenAuthService.create('users');

  try {
    // Simulate login to get initial tokens
    print('1. User logs in...');
    final loginResult = await tokenService.attemptLogin({
      'email': 'user@example.com',
      'password': 'password123',
    });

    print('   Access Token: ${loginResult['token']}');
    print('   Token Type: ${loginResult['token_type']}\n');

    // For token auth, we'd typically store a separate refresh token
    // This is a simplified example
    print('2. Refreshing tokens...');

    // In a real scenario, you'd have a separate refresh token
    const refreshToken = 'stored_refresh_token_from_initial_login';

    final refreshResult = await tokenService.refreshAccessToken(refreshToken);

    print('   New Access Token: ${refreshResult['access_token']}');
    print('   New Refresh Token: ${refreshResult['refresh_token']}');
    print('   Token Type: ${refreshResult['token_type']}');
    print('   Expires In: ${refreshResult['expires_in']} seconds');
    print(
      '   Refresh Expires In: ${refreshResult['refresh_expires_in']} seconds\n',
    );

    print('3. Both old tokens are invalidated for security\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Security Benefits of the Enhanced Implementation
///
/// 1. **Refresh Token Rotation**: Each refresh generates a new refresh token
/// 2. **Old Token Invalidation**: Previous refresh tokens are immediately invalidated
/// 3. **Reduced Attack Surface**: Stolen refresh tokens have limited lifetime
/// 4. **Forward Security**: Compromise of one token doesn't affect future sessions
///
/// Usage in a real application:
///
/// ```dart
/// // In your authentication middleware or interceptor
/// class AuthInterceptor {
///   Future<void> refreshTokenIfNeeded() async {
///     final authService = container.resolve<EnhancedJWTAuthService>();
///
///     if (isAccessTokenExpired()) {
///       try {
///         final refreshToken = getStoredRefreshToken();
///         final newTokens = await authService.refreshAccessToken(refreshToken);
///
///         // Store new tokens
///         await storeAccessToken(newTokens['access_token']);
///         await storeRefreshToken(newTokens['refresh_token']);
///
///         // Update Authorization header for current request
///         updateAuthHeader(newTokens['access_token']);
///
///       } catch (e) {
///         // Refresh failed, redirect to login
///         redirectToLogin();
///       }
///     }
///   }
/// }
/// ```
///
/// Frontend Integration Example:
///
/// ```dart
/// // In your HTTP client
/// class ApiClient {
///   Future<Response> makeRequest(String endpoint) async {
///     var response = await http.get(endpoint, headers: getAuthHeaders());
///
///     if (response.statusCode == 401) {
///       // Token expired, try to refresh
///       final refreshed = await refreshTokens();
///       if (refreshed) {
///         // Retry the original request with new token
///         response = await http.get(endpoint, headers: getAuthHeaders());
///       } else {
///         // Refresh failed, redirect to login
///         throw UnauthorizedException();
///       }
///     }
///
///     return response;
///   }
/// }
/// ```

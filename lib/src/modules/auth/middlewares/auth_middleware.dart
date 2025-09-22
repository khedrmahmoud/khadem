import '../../../application/khadem.dart';
import '../../../contracts/http/middleware_contract.dart';
import '../../../core/http/request/request.dart';
import '../../../core/http/response/response.dart';
import '../exceptions/auth_exception.dart';
import '../services/auth_manager.dart';

/// Authentication middleware for protecting routes
///
/// This middleware intercepts HTTP requests and validates authentication tokens
/// before allowing access to protected routes. It extracts the Bearer token
/// from the Authorization header, verifies it, and attaches user information
/// to the request for use in controllers.
///
/// Features:
/// - Bearer token extraction and validation
/// - Automatic user data attachment to request
/// - Comprehensive error handling
/// - Configurable through auth configuration
///
/// Example usage:
/// ```dart
/// // In routes configuration
/// router.get('/protected', handler, middleware: [AuthMiddleware()]);
///
/// // In controller
/// class ProtectedController {
///   Future<void> index(Request request, Response response) async {
///     final user = request.user; // User data attached by middleware
///     // Handle authenticated request
///   }
/// }
/// ```
class AuthMiddleware extends Middleware {
  /// Creates an authentication middleware instance
  AuthMiddleware() : super(_handleAuth);

  /// Handles the authentication middleware logic
  ///
  /// [req] The incoming HTTP request
  /// [res] The HTTP response (not used in this middleware)
  /// [next] Function to call the next middleware or route handler
  ///
  /// Throws [AuthException] if authentication fails
  static Future<void> _handleAuth(
    Request req,
    Response res,
    NextFunction next,
  ) async {
    try {
      // Extract and validate authorization header
      final authHeader = _extractAuthHeader(req);
      final token = _extractBearerToken(authHeader);

      // Verify token and get user data
      final user = await _verifyToken(token);

      // Attach user data to request
      _attachUserToRequest(req, user);

      // Continue to next middleware/route handler
      await next();
    } catch (e) {
      // Re-throw AuthException with additional context
      if (e is AuthException) {
        throw AuthException(
          e.message,
          statusCode: e.statusCode,
          stackTrace: e.details,
        );
      }

      // Wrap unexpected errors
      throw AuthException(
        'Authentication failed: ${e.toString()}',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }

  /// Extracts the Authorization header from the request
  ///
  /// [request] The HTTP request
  /// Returns the authorization header value
  /// Throws [AuthException] if header is missing or invalid
  static String _extractAuthHeader(Request request) {
    final authHeader = request.header('authorization');

    if (authHeader == null || authHeader.isEmpty) {
      throw AuthException(
        'Missing authorization header. Please provide a Bearer token.',
      );
    }

    return authHeader;
  }

  /// Extracts the Bearer token from the authorization header
  ///
  /// [authHeader] The authorization header value
  /// Returns the extracted token
  /// Throws [AuthException] if header format is invalid
  static String _extractBearerToken(String authHeader) {
    if (!authHeader.startsWith('Bearer ')) {
      throw AuthException(
        'Invalid authorization header format. Expected "Bearer <token>".',
      );
    }

    final token = authHeader.replaceFirst('Bearer ', '').trim();

    if (token.isEmpty) {
      throw AuthException('Empty token provided in authorization header.');
    }

    return token;
  }

  /// Verifies the authentication token
  ///
  /// [token] The token to verify
  /// Returns the user data associated with the token
  /// Throws [AuthException] if token verification fails
  static Future<Map<String, dynamic>> _verifyToken(String token) async {
    final authManager = Khadem.container.resolve<AuthManager>();
    return authManager.verify(token);
  }

  /// Attaches user data to the request
  ///
  /// [request] The HTTP request
  /// [user] The user data to attach
  static void _attachUserToRequest(Request request, Map<String, dynamic> user) {
    request.setAttribute('user', user);
    request.setAttribute('userId', user['id']);
    request.setAttribute('isAuthenticated', true);
    request.setAttribute('isGuest', false);
  }
}

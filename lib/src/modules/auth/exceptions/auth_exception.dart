import '../../../contracts/exceptions/app_exception.dart';

/// Exception thrown for authentication-related errors
///
/// This exception is used throughout the authentication system to indicate
/// various authentication failures such as invalid credentials, expired tokens,
/// missing permissions, etc.
///
/// It extends the base AppException and provides specific status codes
/// appropriate for authentication errors (typically 401 Unauthorized).
///
/// Example usage:
/// ```dart
/// // Throwing an auth exception
/// throw AuthException('Invalid credentials provided');
///
/// // With custom status code
/// throw AuthException('Token expired', statusCode: 401);
///
/// // With stack trace for debugging
/// throw AuthException(
///   'Authentication failed',
///   stackTrace: StackTrace.current.toString(),
/// );
/// ```
class AuthException extends AppException {
  /// Creates an authentication exception
  ///
  /// [message] A human-readable description of the authentication error
  /// [statusCode] HTTP status code (defaults to 401 for auth errors)
  /// [stackTrace] Optional stack trace for debugging purposes
  AuthException(
    super.message, {
    super.statusCode = 401,
    String? stackTrace,
  }) : super(details: stackTrace);
}

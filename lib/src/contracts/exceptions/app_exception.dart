/// Base class for custom application exceptions.
///
/// Extend this class to create specific error types with custom messages,
/// status codes, and optional error details.
///
/// Example:
/// ```dart
/// class UnauthorizedException extends AppException {
///   UnauthorizedException() : super('Unauthorized', statusCode: 401);
/// }
/// ```
abstract class AppException implements Exception {
  /// Human-readable error message.
  final String message;

  /// HTTP-like status code (defaults to 500).
  final int statusCode;

  /// Optional additional information for debugging.
  final dynamic details;

  AppException(this.message, {this.statusCode = 500, this.details});

  /// Converts the exception to a serializable response map.
  Map<String, dynamic> toResponse() => {
        'message': message,
        if (details != null) 'details': details,
      };
}

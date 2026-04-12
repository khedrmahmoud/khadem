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
  /// Human-readable error message (detail).
  final String message;

  /// HTTP-like status code (defaults to 500).
  final int statusCode;

  /// A URI reference that identifies the problem type.
  final String type;

  /// A short, human-readable summary of the problem type.
  final String title;

  /// A URI reference that identifies the specific occurrence of the problem.
  final String? instance;

  /// Optional additional information for debugging.
  final dynamic details;

  AppException(
    this.message, {
    this.statusCode = 500,
    this.type = 'about:blank',
    this.title = 'Application Error',
    this.instance,
    this.details,
  });

  /// Converts the exception to a serializable response map (RFC 7807).
  Map<String, dynamic> toResponse() => {
    'type': type,
    'title': title,
    'status': statusCode,
    'detail': message,
    if (instance != null) 'instance': instance,
    if (details != null) 'extensions': details,
  };

  @override
  String toString() => '$title: $message (Status: $statusCode)';
}

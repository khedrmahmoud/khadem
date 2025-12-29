/// Represents a standardized error result.
///
/// This class is used to pass error information from the [ExceptionHandler]
/// to the transport layer (HTTP, Socket, etc.) in a protocol-agnostic way.
class ErrorResult {
  /// The HTTP status code or equivalent error code.
  final int statusCode;

  /// A short, human-readable summary of the problem type.
  final String title;

  /// A human-readable explanation specific to this occurrence of the problem.
  final String? message;

  /// A URI reference that identifies the problem type.
  final String type;

  /// A URI reference that identifies the specific occurrence of the problem.
  final String? instance;

  /// Additional details about the error (e.g., validation errors).
  final dynamic details;

  /// The stack trace associated with the error.
  final StackTrace? stackTrace;

  /// Additional extensions or metadata.
  final Map<String, dynamic> extensions;

  const ErrorResult({
    required this.statusCode,
    required this.title,
    this.message,
    this.type = 'about:blank',
    this.instance,
    this.details,
    this.stackTrace,
    this.extensions = const {},
  });

  /// Convert to a Map (e.g., for JSON serialization).
  Map<String, dynamic> toMap({bool includeStackTrace = false}) {
    return {
      'type': type,
      'title': title,
      'status': statusCode,
      if (message != null) 'detail': message,
      if (instance != null) 'instance': instance,
      if (details != null) 'details': details,
      ...extensions,
      if (includeStackTrace && stackTrace != null)
        'stack_trace': stackTrace.toString(),
    };
  }
}

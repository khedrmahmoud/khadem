import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a request exceeds rate limits.
///
/// This exception is typically thrown when a client makes too many
/// requests within a given time period.
class TooManyRequestsException extends AppException {
  TooManyRequestsException([
    super.message = 'Too many requests',
    dynamic details,
    this.retryAfter,
  ]) : super(statusCode: 429, details: details);

  /// Number of seconds to wait before retrying
  final int? retryAfter;

  @override
  Map<String, dynamic> toResponse() {
    final response = super.toResponse();
    if (retryAfter != null) {
      response['retry_after'] = retryAfter;
    }
    return response;
  }
}

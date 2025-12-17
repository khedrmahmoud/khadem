import '../../contracts/exceptions/app_exception.dart';

/// Exception thrown when a request exceeds rate limits.
///
/// This exception is typically thrown when a client makes too many
/// requests within a given time period.
class TooManyRequestsException extends AppException {
  /// Number of seconds to wait before retrying
  final int? retryAfter;

  TooManyRequestsException(
    super.message, {
    this.retryAfter,
    super.details,
  }) : super(
          statusCode: 429,
          title: 'Too Many Requests',
          type: 'too_many_requests',
        );

  @override
  Map<String, dynamic> toResponse() {
    final response = super.toResponse();
    if (retryAfter != null) {
      response['retry_after'] = retryAfter;
    }
    return response;
  }
}

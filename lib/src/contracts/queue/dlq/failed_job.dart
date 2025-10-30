/// Represents a failed job stored in the Dead Letter Queue
class FailedJob {
  final String id;
  final String jobType;
  final Map<String, dynamic> payload;
  final String error;
  final String? stackTrace;
  final DateTime failedAt;
  final int attempts;
  final Map<String, dynamic> metadata;

  FailedJob({
    required this.id,
    required this.jobType,
    required this.payload,
    required this.error,
    required this.failedAt,
    required this.attempts,
    this.stackTrace,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobType': jobType,
        'payload': payload,
        'error': error,
        'stackTrace': stackTrace,
        'failedAt': failedAt.toIso8601String(),
        'attempts': attempts,
        'metadata': metadata,
      };

  factory FailedJob.fromJson(Map<String, dynamic> json) {
    return FailedJob(
      id: json['id'] as String,
      jobType: json['jobType'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      error: json['error'] as String,
      stackTrace: json['stackTrace'] as String?,
      failedAt: DateTime.parse(json['failedAt'] as String),
      attempts: json['attempts'] as int,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() {
    return 'FailedJob{id: $id, type: $jobType, error: $error, attempts: $attempts, failedAt: $failedAt}';
  }
}

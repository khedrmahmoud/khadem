/// Represents a job that can be queued and processed asynchronously.
///
/// Just extend QueueJob and implement handle()!
///
/// ## Simple Jobs (Memory/Sync drivers)
/// For memory and sync drivers, no serialization is needed:
/// ```dart
/// class SendEmailJob extends QueueJob {
///   final String email;
///
///   SendEmailJob(this.email);
///
///   @override
///   Future<void> handle() async {
///     await sendEmail(email);
///   }
/// }
///
/// // Dispatch it
/// queueManager.dispatch(SendEmailJob('user@example.com'));
/// ```
///
/// ## Serializable Jobs (File/Redis/Database drivers)
/// For persistent drivers, jobs must be serializable and registered:
/// ```dart
/// class SendEmailJob extends QueueJob with SerializableJob {
///   final String email;
///
///   SendEmailJob(this.email);
///
///   factory SendEmailJob.fromJson(Map<String, dynamic> json) {
///     return SendEmailJob(json['email'] as String);
///   }
///
///   @override
///   Map<String, dynamic> toJson() => {'email': email};
///
///   @override
///   Future<void> handle() async {
///     await sendEmail(email);
///   }
/// }
///
/// // Register at startup
/// QueueJobRegistry.register('SendEmailJob', (json) => SendEmailJob.fromJson(json));
///
/// // Then dispatch as normal
/// queueManager.dispatch(SendEmailJob('user@example.com'));
/// ```
abstract class QueueJob {
  /// Called when the job is executed.
  /// Put your job logic here.
  Future<void> handle();

  /// Optional: Job display name for logging/debugging.
  /// Defaults to the class name.
  String get displayName => runtimeType.toString();

  /// Optional: Number of times to retry this job on failure.
  /// Default is 3 attempts.
  int get maxRetries => 3;

  /// Optional: Delay between retry attempts.
  /// Default is 30 seconds.
  Duration get retryDelay => const Duration(seconds: 30);

  /// Optional: Whether this job should be retried on failure.
  /// Default is true.
  bool get shouldRetry => true;

  /// Optional: Job timeout. Job will be killed if it takes longer.
  /// Default is no timeout.
  Duration? get timeout => null;

  /// Optional: Queue name to dispatch this job to.
  /// Default is 'default'.
  String get queue => 'default';

  /// Returns the job data as a JSON-encoded string.
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'maxRetries': maxRetries,
      'retryDelay': retryDelay.inSeconds,
      'shouldRetry': shouldRetry,
      'timeout': timeout?.inSeconds,
      'queue': queue,
    };
  }
}

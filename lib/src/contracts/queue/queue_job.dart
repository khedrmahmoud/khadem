import '../../core/queue/job_registry.dart';

/// Represents a job that can be queued and processed asynchronously.
///
/// Every job must implement [handle] for logic execution,
/// and provide serialization via [toJson] and [fromJson] to allow persistence.
///
/// Example:
/// ```dart
/// class SendEmailJob extends QueueJob {
///   final String email;
///
///   SendEmailJob(this.email);
///
///   @override
///   Future<void> handle() async {
///     print("Sending email to $email");
///   }
///
///   @override
///   Map<String, dynamic> toJson() => {'email': email};
///
///   @override
///   SendEmailJob fromJson(Map<String, dynamic> json) => SendEmailJob(json['email']);
/// }
/// ```
abstract class QueueJob {
  /// Called when the job is executed.
  Future<void> handle();

  /// Converts this job instance to JSON for storage.
  Map<String, dynamic> toJson();

  /// Rebuilds this job instance from JSON.
  QueueJob fromJson(Map<String, dynamic> json);

  /// Registers the job in the global [QueueJobRegistry] using its type name.
  ///
  /// Required for deserialization during job processing.
  ///
  /// Call this inside your job constructor or initialization logic.
  ///
  /// Example:
  /// ```dart
  /// SendEmailJob().register();
  /// ```
  void register() {
    QueueJobRegistry.register(runtimeType.toString(), (json) => fromJson(json));
  }
}

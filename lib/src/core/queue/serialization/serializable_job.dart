import '../../../contracts/queue/queue_job.dart';

/// Mixin for jobs that need to be serialized (for file/Redis drivers)
///
/// Jobs using persistent drivers (file, Redis, database) need to be serializable
/// so they can be stored and reconstructed later. This mixin provides a standard
/// pattern for serialization.
///
/// Example:
/// ```dart
/// class SendEmailJob extends QueueJob with SerializableJob {
///   final String email;
///   final String subject;
///   final String body;
///
///   SendEmailJob(this.email, this.subject, this.body);
///
///   // Factory constructor for deserialization
///   factory SendEmailJob.fromJson(Map<String, dynamic> json) {
///     return SendEmailJob(
///       json['email'] as String,
///       json['subject'] as String,
///       json['body'] as String,
///     );
///   }
///
///   @override
///   Map<String, dynamic> toJson() => {
///     'email': email,
///     'subject': subject,
///     'body': body,
///   };
///
///   @override
///   Future<void> handle() async {
///     await EmailService.send(email, subject, body);
///   }
/// }
///
/// // Register at application startup
/// QueueJobRegistry.register('SendEmailJob', (json) => SendEmailJob.fromJson(json));
/// ```
mixin SerializableJob on QueueJob {
  /// Convert job to JSON for serialization
  ///
  /// Override this to include all data needed to reconstruct the job.
  /// Don't include job metadata (maxRetries, displayName, etc.) - those
  /// are handled automatically by the queue system.
  @override
  Map<String, dynamic> toJson();
}

/// Base class for serializable jobs that provides common patterns
///
/// This is an alternative to using the mixin if you prefer inheritance.
///
/// Example:
/// ```dart
/// class ProcessPaymentJob extends SerializableQueueJob {
///   final String orderId;
///   final double amount;
///
///   ProcessPaymentJob(this.orderId, this.amount);
///
///   factory ProcessPaymentJob.fromJson(Map<String, dynamic> json) {
///     return ProcessPaymentJob(
///       json['orderId'] as String,
///       json['amount'] as double,
///     );
///   }
///
///   @override
///   Map<String, dynamic> toJson() => {
///     'orderId': orderId,
///     'amount': amount,
///   };
///
///   @override
///   Future<void> handle() async {
///     await PaymentService.process(orderId, amount);
///   }
/// }
/// ```
abstract class SerializableQueueJob extends QueueJob {
  /// Convert job to JSON for serialization
  @override
  Map<String, dynamic> toJson();
}

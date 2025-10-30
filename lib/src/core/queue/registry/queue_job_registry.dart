import '../../../contracts/queue/queue_job.dart';
import '../../../support/exceptions/queue_exception.dart';

/// Factory function type for creating jobs from JSON
typedef JobFactory = QueueJob Function(Map<String, dynamic> json);

/// Registry for queue job types to enable deserialization
///
/// Since jobs are serialized when pushed to persistent queues (file, Redis, etc.),
/// we need a way to reconstruct them when they're pulled from the queue.
///
/// Usage:
/// ```dart
/// // Register your job types at application startup
/// QueueJobRegistry.register('SendEmailJob', (json) => SendEmailJob.fromJson(json));
/// QueueJobRegistry.register('ProcessPaymentJob', (json) => ProcessPaymentJob.fromJson(json));
///
/// // Jobs can now be automatically reconstructed from storage
/// ```
class QueueJobRegistry {
  static final QueueJobRegistry _instance = QueueJobRegistry._internal();
  factory QueueJobRegistry() => _instance;
  QueueJobRegistry._internal();

  final Map<String, JobFactory> _factories = {};

  /// Register a job type with its factory function
  ///
  /// The factory function should create an instance of the job from its JSON representation.
  ///
  /// Example:
  /// ```dart
  /// QueueJobRegistry.register('SendEmailJob', (json) {
  ///   return SendEmailJob(
  ///     json['email'] as String,
  ///     json['subject'] as String,
  ///     json['body'] as String,
  ///   );
  /// });
  /// ```
  static void register(String jobType, JobFactory factory) {
    _instance._factories[jobType] = factory;
  }

  /// Register multiple job types at once
  ///
  /// Example:
  /// ```dart
  /// QueueJobRegistry.registerAll({
  ///   'SendEmailJob': (json) => SendEmailJob.fromJson(json),
  ///   'ProcessPaymentJob': (json) => ProcessPaymentJob.fromJson(json),
  ///   'GenerateReportJob': (json) => GenerateReportJob.fromJson(json),
  /// });
  /// ```
  static void registerAll(Map<String, JobFactory> factories) {
    _instance._factories.addAll(factories);
  }

  /// Create a job instance from its type name and JSON data
  ///
  /// Throws [QueueException] if the job type is not registered.
  static QueueJob create(String jobType, Map<String, dynamic> json) {
    final factory = _instance._factories[jobType];
    if (factory == null) {
      throw QueueException(
        'Job type "$jobType" is not registered. '
        'Register it with QueueJobRegistry.register() before dispatching.',
      );
    }
    return factory(json);
  }

  /// Check if a job type is registered
  static bool isRegistered(String jobType) {
    return _instance._factories.containsKey(jobType);
  }

  /// Get all registered job types
  static List<String> getRegisteredTypes() {
    return _instance._factories.keys.toList();
  }

  /// Clear all registered job types (useful for testing)
  static void clear() {
    _instance._factories.clear();
  }

  /// Get the number of registered job types
  static int get count => _instance._factories.length;
}

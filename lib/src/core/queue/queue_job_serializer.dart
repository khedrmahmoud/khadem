import '../../contracts/queue/queue_job.dart';

/// Factory function type for creating queue jobs from JSON.
typedef QueueJobFactory = QueueJob Function(Map<String, dynamic> json);

/// Handles serialization and deserialization of queue jobs.
/// Provides a centralized way to convert jobs to/from JSON format.
class QueueJobSerializer {
  final Map<String, QueueJobFactory> _factories = {};

  /// Registers a job factory for deserialization.
  void registerFactory(String type, QueueJobFactory factory) {
    _factories[type] = factory;
  }

  /// Serializes a job to JSON format with metadata.
  Map<String, dynamic> serialize(QueueJob job) {
    final json = job.toJson();
    json['type'] = job.runtimeType.toString();
    json['created_at'] = DateTime.now().toIso8601String();
    return json;
  }

  /// Deserializes a job from JSON format.
  QueueJob deserialize(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw QueueSerializationException('Job type not specified in JSON');
    }

    final factory = _factories[type];
    if (factory == null) {
      throw QueueSerializationException('No factory registered for job type: $type');
    }

    try {
      return factory(json);
    } catch (e) {
      throw QueueSerializationException('Failed to deserialize job of type $type: $e');
    }
  }

  /// Checks if a factory is registered for the given type.
  bool hasFactory(String type) {
    return _factories.containsKey(type);
  }

  /// Gets all registered job types.
  Set<String> getRegisteredTypes() {
    return _factories.keys.toSet();
  }
}

/// Exception thrown when job serialization/deserialization fails.
class QueueSerializationException implements Exception {
  final String message;

  QueueSerializationException(this.message);

  @override
  String toString() => 'QueueSerializationException: $message';
}

/// Enhanced queue job with metadata support.
/// Extend this class instead of QueueJob for jobs that need retry logic and metadata.
abstract class QueueJobWithMetadata implements QueueJob {
  /// Maximum number of retry attempts for this job.
  int get maxAttempts => 3;

  /// Delay between retry attempts.
  Duration get retryDelay => const Duration(seconds: 30);

  /// Job priority (higher numbers = higher priority).
  int get priority => 0;

  /// Whether this job should be retried on failure.
  bool get shouldRetry => true;

  /// Current attempt number (0-based).
  int attempt = 0;

  /// Job creation timestamp.
  DateTime? createdAt;

  /// Job processing start timestamp.
  DateTime? startedAt;

  /// Job completion timestamp.
  DateTime? completedAt;

  /// Error message from last failure.
  String? lastError;

  /// Marks the job as started.
  void markStarted() {
    startedAt = DateTime.now();
    attempt++;
  }

  /// Marks the job as completed.
  void markCompleted() {
    completedAt = DateTime.now();
  }

  /// Records a failure.
  void recordFailure(String error) {
    lastError = error;
  }

  /// Checks if the job should be retried.
  bool canRetry() {
    return shouldRetry && attempt < maxAttempts;
  }

  /// Gets the delay before next retry.
  Duration getNextRetryDelay() {
    return retryDelay * attempt; // Exponential backoff
  }

  /// Enhanced toJson that includes metadata.
  Map<String, dynamic> toJsonWithMetadata() {
    final json = toJson();
    json.addAll({
      'attempt': attempt,
      'created_at': createdAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'last_error': lastError,
      'max_attempts': maxAttempts,
      'retry_delay_ms': retryDelay.inMilliseconds,
      'priority': priority,
      'should_retry': shouldRetry,
    });
    return json;
  }

  /// Enhanced fromJson that handles metadata.
  void fromJsonWithMetadata(Map<String, dynamic> json) {
    attempt = json['attempt'] ?? 0;
    createdAt = json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    startedAt = json['started_at'] != null ? DateTime.parse(json['started_at']) : null;
    completedAt = json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null;
    lastError = json['last_error'];
  }
}

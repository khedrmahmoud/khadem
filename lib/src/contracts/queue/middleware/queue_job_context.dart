import '../queue_job.dart';

/// Context passed through the middleware pipeline
class QueueJobContext {
  final QueueJob job;
  final Map<String, dynamic> metadata;
  final DateTime startedAt;
  dynamic result;
  dynamic error;
  StackTrace? stackTrace;

  QueueJobContext({
    required this.job,
    Map<String, dynamic>? metadata,
  })  : metadata = metadata ?? {},
        startedAt = DateTime.now();

  /// Duration since job started
  Duration get elapsed => DateTime.now().difference(startedAt);

  /// Check if job has error
  bool get hasError => error != null;

  /// Check if job completed successfully
  bool get isSuccess => error == null && result != null;

  /// Add metadata
  void addMetadata(String key, dynamic value) {
    metadata[key] = value;
  }

  /// Get metadata
  T? getMetadata<T>(String key) => metadata[key] as T?;
}

import '../../../contracts/queue/queue_job.dart';
import 'base_driver.dart';

/// Synchronous queue driver that executes jobs immediately
///
/// This driver executes jobs synchronously without queuing.
/// Perfect for:
/// - Testing and development
/// - Jobs that must run immediately
/// - Debugging job logic
/// - Simple applications without async requirements
///
/// Features:
/// - Immediate execution
/// - No queuing overhead
/// - Full metrics tracking
/// - Middleware support
/// - Exception handling
///
/// Example:
/// ```dart
/// final driver = SynchronousDriver(
///   config: DriverConfig(name: 'sync'),
///   middleware: middleware,
/// );
///
/// // Job executes immediately on push
/// await driver.push(SendEmailJob('user@example.com'));
/// ```
class SynchronousDriver extends BaseQueueDriver {
  SynchronousDriver({
    required super.config,
    super.metrics,
    super.dlqHandler,
    super.middleware,
  });

  @override
  Future<void> push(QueueJob job, {Duration? delay}) async {
    final context = createJobContext(job, delay: delay);

    // Track metrics
    if (metrics != null) {
      metrics!.jobQueued(job.runtimeType.toString());
    }

    // Handle delay
    if (delay != null && delay > Duration.zero) {
      await Future.delayed(delay);
    }

    // Execute immediately
    await executeJob(context);
  }

  @override
  Future<void> process() async {
    // Nothing to process - jobs are executed immediately on push
  }

  @override
  Future<void> retryJob(JobContext context, {required Duration delay}) async {
    // Wait for retry delay
    await Future.delayed(delay);

    // Re-execute the job
    await executeJob(context);
  }

  @override
  Future<void> clear() async {
    // Nothing to clear - no queue exists
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final baseStats = await super.getStats();

    return {
      ...baseStats,
      'execution_mode': 'synchronous',
      'queue_depth': 0, // Always 0 as jobs execute immediately
    };
  }
}

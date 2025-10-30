import 'dart:async';

import 'package:khadem/src/contracts/queue/middleware/index.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/middleware/index.dart';
import 'package:test/test.dart';

// Test job implementation
class TestJob extends QueueJob {
  bool executed = false;
  bool shouldFail = false;
  Duration? executionDelay;
  Future<void> Function()? customHandle;

  TestJob({
    this.shouldFail = false,
    this.executionDelay,
    this.customHandle,
  });

  @override
  Future<void> handle() async {
    if (customHandle != null) {
      await customHandle!();
      return;
    }

    if (executionDelay != null) {
      await Future.delayed(executionDelay!);
    }

    if (shouldFail) {
      throw Exception('Test job failed');
    }

    executed = true;
  }

  @override
  String get displayName => 'TestJob';
}

// Test middleware for tracking execution
class TrackingMiddleware implements QueueMiddleware {
  final List<String> executionLog = [];

  @override
  Future<void> handle(QueueJobContext context, Next next) async {
    executionLog.add('before');
    await next();
    executionLog.add('after');
  }

  @override
  String get name => 'TrackingMiddleware';
}

void main() {
  group('QueueJobContext', () {
    test('should create context with job and metadata', () {
      final job = TestJob();
      final context = QueueJobContext(
        job: job,
        metadata: {'key': 'value'},
      );

      expect(context.job, equals(job));
      expect(context.metadata['key'], equals('value'));
      expect(context.startedAt, isA<DateTime>());
    });

    test('should track elapsed time', () async {
      final context = QueueJobContext(job: TestJob());

      await Future.delayed(const Duration(milliseconds: 100));

      expect(context.elapsed.inMilliseconds, greaterThan(90));
    });

    test('should track error state', () {
      final context = QueueJobContext(job: TestJob());

      expect(context.hasError, isFalse);

      context.error = Exception('Test error');
      expect(context.hasError, isTrue);
    });

    test('should track success state', () {
      final context = QueueJobContext(job: TestJob());

      expect(context.isSuccess, isFalse);

      context.result = true;
      expect(context.isSuccess, isTrue);
    });

    test('should add and get metadata', () {
      final context = QueueJobContext(job: TestJob());

      context.addMetadata('attempts', 3);
      expect(context.getMetadata<int>('attempts'), equals(3));

      context.addMetadata('startTime', DateTime.now());
      expect(context.getMetadata<DateTime>('startTime'), isA<DateTime>());
    });
  });

  group('QueueMiddlewarePipeline', () {
    test('should execute job without middleware', () async {
      final pipeline = QueueMiddlewarePipeline();
      final job = TestJob();
      final context = QueueJobContext(job: job);

      await pipeline.execute(context);

      expect(job.executed, isTrue);
      expect(context.result, isTrue);
    });

    test('should execute middleware in order', () async {
      final pipeline = QueueMiddlewarePipeline();
      final middleware1 = TrackingMiddleware();
      final middleware2 = TrackingMiddleware();

      pipeline.add(middleware1);
      pipeline.add(middleware2);

      final job = TestJob();
      await pipeline.execute(QueueJobContext(job: job));

      expect(middleware1.executionLog, equals(['before', 'after']));
      expect(middleware2.executionLog, equals(['before', 'after']));
      expect(job.executed, isTrue);
    });

    test('should add middleware at specific position', () async {
      final pipeline = QueueMiddlewarePipeline();
      final tracking = TrackingMiddleware();

      pipeline.add(TrackingMiddleware());
      pipeline.addAt(0, tracking);

      expect(pipeline.count, equals(2));
      expect(pipeline.middleware.first, equals(tracking));
    });

    test('should remove middleware', () {
      final pipeline = QueueMiddlewarePipeline();
      final middleware = TrackingMiddleware();

      pipeline.add(middleware);
      expect(pipeline.count, equals(1));

      pipeline.remove(middleware);
      expect(pipeline.count, equals(0));
    });

    test('should clear all middleware', () {
      final pipeline = QueueMiddlewarePipeline();

      pipeline.add(TrackingMiddleware());
      pipeline.add(TrackingMiddleware());
      expect(pipeline.count, equals(2));

      pipeline.clear();
      expect(pipeline.count, equals(0));
    });

    test('should propagate job errors', () async {
      final pipeline = QueueMiddlewarePipeline();
      final job = TestJob(shouldFail: true);
      final context = QueueJobContext(job: job);

      expect(
        () => pipeline.execute(context),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('QueueLoggingMiddleware', () {
    test('should log job start and completion', () async {
      final logs = <String>[];
      final middleware = QueueLoggingMiddleware(
        logger: logs.add,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob();
      await pipeline.execute(QueueJobContext(job: job));

      expect(logs.length, equals(2));
      expect(logs[0], contains('Starting job'));
      expect(logs[1], contains('Job completed'));
      expect(logs[1], contains('ms'));
    });

    test('should log job failure', () async {
      final logs = <String>[];
      final middleware = QueueLoggingMiddleware(
        logger: logs.add,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(shouldFail: true);

      try {
        await pipeline.execute(QueueJobContext(job: job));
      } catch (_) {
        // Expected
      }

      expect(logs.length, equals(2));
      expect(logs[0], contains('Starting job'));
      expect(logs[1], contains('Job failed'));
    });

    test('should use default print logger if none provided', () async {
      final middleware = QueueLoggingMiddleware();

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob();
      // Should not throw, will print to console
      await pipeline.execute(QueueJobContext(job: job));
    });
  });

  group('TimingMiddleware', () {
    test('should track job execution time', () async {
      Duration? recordedDuration;
      String? recordedJobName;

      final middleware = TimingMiddleware(
        onComplete: (name, duration) {
          recordedJobName = name;
          recordedDuration = duration;
        },
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(executionDelay: const Duration(milliseconds: 100));
      await pipeline.execute(QueueJobContext(job: job));

      expect(recordedJobName, equals('TestJob'));
      expect(recordedDuration, isNotNull);
      expect(recordedDuration!.inMilliseconds, greaterThan(90));
    });

    test('should add processing time to metadata', () async {
      final middleware = TimingMiddleware();
      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(executionDelay: const Duration(milliseconds: 50));
      final context = QueueJobContext(job: job);

      await pipeline.execute(context);

      final duration = context.getMetadata<Duration>('processingTime');
      expect(duration, isNotNull);
      expect(duration!.inMilliseconds, greaterThan(40));
    });

    test('should track time even on failure', () async {
      final middleware = TimingMiddleware();
      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(shouldFail: true);
      final context = QueueJobContext(job: job);

      try {
        await pipeline.execute(context);
      } catch (_) {
        // Expected
      }

      final duration = context.getMetadata<Duration>('processingTime');
      expect(duration, isNotNull);
    });
  });

  group('RetryMiddleware', () {
    test('should retry failed jobs', () async {
      int attempts = 0;
      final job = TestJob(
        customHandle: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Attempt $attempts failed');
          }
        },
      );

      final middleware = RetryMiddleware(
        delay: const Duration(milliseconds: 10),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final context = QueueJobContext(job: job);
      await pipeline.execute(context);

      // Should succeed after 3 attempts
      expect(attempts, equals(3));
      expect(context.getMetadata<int>('attempts'),
          equals(2),); // 2 retries after first attempt
    });

    test('should respect max attempts', () async {
      final job = TestJob(shouldFail: true);

      final middleware = RetryMiddleware(
        maxAttempts: 2,
        delay: const Duration(milliseconds: 10),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final context = QueueJobContext(job: job);

      try {
        await pipeline.execute(context);
        fail('Should have thrown exception');
      } catch (e) {
        // Expected exception
        expect(e, isA<Exception>());
      }

      // Should attempt twice, so attempts metadata should be 2
      expect(context.getMetadata<int>('attempts'), equals(2));
    });

    test('should use shouldRetry predicate', () async {
      int attempts = 0;
      final job = TestJob(
        customHandle: () async {
          attempts++;
          throw const FormatException('Non-retryable error');
        },
      );

      final middleware = RetryMiddleware(
        delay: const Duration(milliseconds: 10),
        shouldRetry: (error) => error is! FormatException,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      expect(
        () => pipeline.execute(QueueJobContext(job: job)),
        throwsA(isA<FormatException>()),
      );

      // Should not retry FormatException
      expect(attempts, equals(1));
    });

    test('should increase delay with each retry', () async {
      int attempts = 0;
      final retryTimes = <DateTime>[];
      final job = TestJob(
        customHandle: () async {
          attempts++;
          retryTimes.add(DateTime.now());
          if (attempts < 3) {
            throw Exception('Retry');
          }
        },
      );

      final middleware = RetryMiddleware(
        delay: const Duration(milliseconds: 100),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      await pipeline.execute(QueueJobContext(job: job));

      expect(attempts, equals(3));

      // Check delay increases (1x, 2x)
      final delay1 = retryTimes[1].difference(retryTimes[0]).inMilliseconds;
      final delay2 = retryTimes[2].difference(retryTimes[1]).inMilliseconds;

      expect(delay1, greaterThan(90)); // ~100ms
      expect(delay2, greaterThan(190)); // ~200ms
    });
  });

  group('TimeoutMiddleware', () {
    test('should timeout long-running jobs', () async {
      final middleware = TimeoutMiddleware(
        timeout: const Duration(milliseconds: 100),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(executionDelay: const Duration(seconds: 1));

      expect(
        () => pipeline.execute(QueueJobContext(job: job)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should not timeout fast jobs', () async {
      final middleware = TimeoutMiddleware(
        timeout: const Duration(milliseconds: 200),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(executionDelay: const Duration(milliseconds: 50));

      await pipeline.execute(QueueJobContext(job: job));

      expect(job.executed, isTrue);
    });
  });

  group('RateLimitMiddleware', () {
    test('should limit job execution rate', () async {
      final middleware = RateLimitMiddleware(
        maxJobsPerSecond: 2,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final startTime = DateTime.now();

      // Execute 3 jobs (should delay the 3rd)
      for (int i = 0; i < 3; i++) {
        await pipeline.execute(QueueJobContext(job: TestJob()));
      }

      final elapsed = DateTime.now().difference(startTime);

      // Should take at least 1 second for the 3rd job
      expect(elapsed.inMilliseconds, greaterThan(900));
    });

    test('should allow jobs within rate limit', () async {
      final middleware = RateLimitMiddleware(
        maxJobsPerSecond: 10,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final startTime = DateTime.now();

      // Execute 5 jobs (all should be fast)
      for (int i = 0; i < 5; i++) {
        await pipeline.execute(QueueJobContext(job: TestJob()));
      }

      final elapsed = DateTime.now().difference(startTime);

      // Should complete quickly
      expect(elapsed.inMilliseconds, lessThan(500));
    });
  });

  group('ErrorHandlingMiddleware', () {
    test('should call onError callback', () async {
      dynamic capturedError;
      QueueJob? capturedJob;

      final middleware = ErrorHandlingMiddleware(
        onError: (job, error, stack) {
          capturedJob = job;
          capturedError = error;
        },
        rethrowErrors: false,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(shouldFail: true);
      await pipeline.execute(QueueJobContext(job: job));

      expect(capturedJob, equals(job));
      expect(capturedError, isA<Exception>());
    });

    test('should rethrow errors when configured', () async {
      final middleware = ErrorHandlingMiddleware();

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(shouldFail: true);

      expect(
        () => pipeline.execute(QueueJobContext(job: job)),
        throwsA(isA<Exception>()),
      );
    });

    test('should suppress errors when configured', () async {
      final middleware = ErrorHandlingMiddleware(
        rethrowErrors: false,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(shouldFail: true);

      // Should not throw
      await pipeline.execute(QueueJobContext(job: job));
    });
  });

  group('ConditionalMiddleware', () {
    test('should execute middleware when condition is true', () async {
      final tracking = TrackingMiddleware();

      final middleware = ConditionalMiddleware(
        condition: (context) => true,
        middleware: tracking,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      await pipeline.execute(QueueJobContext(job: TestJob()));

      expect(tracking.executionLog, equals(['before', 'after']));
    });

    test('should skip middleware when condition is false', () async {
      final tracking = TrackingMiddleware();

      final middleware = ConditionalMiddleware(
        condition: (context) => false,
        middleware: tracking,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      await pipeline.execute(QueueJobContext(job: TestJob()));

      expect(tracking.executionLog, isEmpty);
    });

    test('should evaluate condition based on context', () async {
      final tracking = TrackingMiddleware();

      final middleware = ConditionalMiddleware(
        condition: (context) => context.metadata.containsKey('shouldRun'),
        middleware: tracking,
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      // Without metadata
      await pipeline.execute(QueueJobContext(job: TestJob()));
      expect(tracking.executionLog, isEmpty);

      // With metadata
      tracking.executionLog.clear();
      await pipeline.execute(
        QueueJobContext(
          job: TestJob(),
          metadata: {'shouldRun': true},
        ),
      );
      expect(tracking.executionLog, equals(['before', 'after']));
    });
  });

  group('HookMiddleware', () {
    test('should execute before and after hooks', () async {
      final executionOrder = <String>[];

      final middleware = HookMiddleware(
        before: (context) async {
          executionOrder.add('before');
        },
        after: (context) async {
          executionOrder.add('after');
        },
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(
        customHandle: () async {
          executionOrder.add('job');
        },
      );

      await pipeline.execute(QueueJobContext(job: job));

      expect(executionOrder, equals(['before', 'job', 'after']));
    });

    test('should execute after hook even on failure', () async {
      bool afterExecuted = false;

      final middleware = HookMiddleware(
        after: (context) async {
          afterExecuted = true;
        },
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final job = TestJob(shouldFail: true);

      try {
        await pipeline.execute(QueueJobContext(job: job));
      } catch (_) {
        // Expected
      }

      expect(afterExecuted, isTrue);
    });

    test('should work with only before hook', () async {
      bool beforeExecuted = false;

      final middleware = HookMiddleware(
        before: (context) async {
          beforeExecuted = true;
        },
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      await pipeline.execute(QueueJobContext(job: TestJob()));

      expect(beforeExecuted, isTrue);
    });

    test('should work with only after hook', () async {
      bool afterExecuted = false;

      final middleware = HookMiddleware(
        after: (context) async {
          afterExecuted = true;
        },
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      await pipeline.execute(QueueJobContext(job: TestJob()));

      expect(afterExecuted, isTrue);
    });
  });

  group('DeduplicationMiddleware', () {
    test('should prevent duplicate job execution within window', () async {
      int executionCount = 0;

      final middleware = DeduplicationMiddleware(
        window: const Duration(seconds: 1),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final createJob = () {
        return TestJob(
          customHandle: () async {
            executionCount++;
          },
        );
      };

      final context1 = QueueJobContext(
        job: createJob(),
        metadata: {'job_id': 'test-job-123'},
      );

      final context2 = QueueJobContext(
        job: createJob(),
        metadata: {'job_id': 'test-job-123'},
      );

      // Execute same job ID twice
      await pipeline.execute(context1);
      await pipeline.execute(context2);

      // Second execution should be skipped (duplicate)
      expect(executionCount, equals(1));
    });

    test('should allow different job IDs', () async {
      int executionCount = 0;

      final middleware = DeduplicationMiddleware(
        window: const Duration(seconds: 1),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final createJob = () {
        return TestJob(
          customHandle: () async {
            executionCount++;
          },
        );
      };

      final context1 = QueueJobContext(
        job: createJob(),
        metadata: {'job_id': 'job-1'},
      );

      final context2 = QueueJobContext(
        job: createJob(),
        metadata: {'job_id': 'job-2'},
      );

      // Execute different job IDs
      await pipeline.execute(context1);
      await pipeline.execute(context2);

      // Both should execute
      expect(executionCount, equals(2));
    });

    test('should allow execution after window expires', () async {
      int executionCount = 0;

      final middleware = DeduplicationMiddleware(
        window: const Duration(milliseconds: 100),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final createJob = () {
        return TestJob(
          customHandle: () async {
            executionCount++;
          },
        );
      };

      final context1 = QueueJobContext(
        job: createJob(),
        metadata: {'job_id': 'test-job'},
      );

      // Execute job
      await pipeline.execute(context1);
      expect(executionCount, equals(1));

      // Wait for window to expire
      await Future.delayed(const Duration(milliseconds: 150));

      final context2 = QueueJobContext(
        job: createJob(),
        metadata: {'job_id': 'test-job'},
      );

      // Try again (should execute after expiration)
      await pipeline.execute(context2);
      expect(executionCount, equals(2));
    });

    test('should execute jobs without job_id metadata', () async {
      int executionCount = 0;

      final middleware = DeduplicationMiddleware(
        window: const Duration(seconds: 1),
      );

      final pipeline = QueueMiddlewarePipeline();
      pipeline.add(middleware);

      final createJob = () {
        return TestJob(
          customHandle: () async {
            executionCount++;
          },
        );
      };

      // Execute jobs without job_id (should always execute)
      await pipeline.execute(QueueJobContext(job: createJob()));
      await pipeline.execute(QueueJobContext(job: createJob()));

      expect(executionCount, equals(2));
    });
  });

  group('Middleware Composition', () {
    test('should compose multiple middleware correctly', () async {
      final logs = <String>[];
      final executionOrder = <String>[];

      final pipeline = QueueMiddlewarePipeline();

      pipeline.add(QueueLoggingMiddleware(logger: logs.add));
      pipeline.add(TimingMiddleware());
      pipeline.add(
        HookMiddleware(
          before: (_) async => executionOrder.add('hook-before'),
          after: (_) async => executionOrder.add('hook-after'),
        ),
      );

      final job = TestJob(
        customHandle: () async {
          executionOrder.add('job');
        },
      );

      final context = QueueJobContext(job: job);
      await pipeline.execute(context);

      expect(job.executed, isFalse); // Custom handle doesn't set executed flag
      expect(logs.length, equals(2));
      expect(executionOrder, equals(['hook-before', 'job', 'hook-after']));
      expect(context.getMetadata<Duration>('processingTime'), isNotNull);
    });

    test('should handle errors through middleware chain', () async {
      dynamic capturedError;

      final pipeline = QueueMiddlewarePipeline();

      pipeline.add(
        ErrorHandlingMiddleware(
          onError: (job, error, stack) => capturedError = error,
          rethrowErrors: false,
        ),
      );
      pipeline.add(QueueLoggingMiddleware());

      final job = TestJob(shouldFail: true);
      await pipeline.execute(QueueJobContext(job: job));

      expect(capturedError, isA<Exception>());
    });
  });
}

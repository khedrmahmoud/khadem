import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/queue_worker.dart';

// Mock QueueDriver for testing
class MockQueueDriver extends Mock implements QueueDriver {
  @override
  Future<void> push(QueueJob job, {Duration? delay}) {
    return super.noSuchMethod(
      Invocation.method(#push, [job], {#delay: delay}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> process() {
    return super.noSuchMethod(
      Invocation.method(#process, []),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }
}

// Test job implementation
class TestQueueJob extends QueueJob {
  final String name;
  bool executed = false;
  Duration? executionDelay;

  TestQueueJob(this.name, {this.executionDelay});

  @override
  Future<void> handle() async {
    executed = true;
    if (executionDelay != null) {
      await Future.delayed(executionDelay!);
    }
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class FailingQueueJob extends QueueJob {
  final String name;
  final Exception error;

  FailingQueueJob(this.name, {Exception? error}) : error = error ?? Exception('Job failed');

  @override
  Future<void> handle() async {
    throw this.error;
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

void main() {
  group('QueueWorker', () {
    late MockQueueDriver mockDriver;
    late QueueWorker worker;
    late QueueWorkerConfig config;

    setUp(() {
      mockDriver = MockQueueDriver();
      config = const QueueWorkerConfig();
      worker = QueueWorker(mockDriver, config);
    });

    test('should initialize with driver and config', () {
      expect(worker, isNotNull);
    });

    test('should start and process jobs', () async {
      when(mockDriver.process()).thenAnswer((_) async {
        // Simulate processing one job
        await Future.delayed(const Duration(milliseconds: 10));
      });

      // Start worker with timeout to prevent infinite loop
      final workerWithTimeout = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(maxJobs: 1, timeout: Duration(milliseconds: 50)),
      );

      await expectLater(workerWithTimeout.start(), completes);

      verify(mockDriver.process()).called(greaterThan(0));
    });

    test('should handle job processing errors gracefully', () async {
      when(mockDriver.process()).thenThrow(Exception('Processing failed'));

      final workerWithTimeout = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(maxJobs: 1, timeout: Duration(milliseconds: 50)),
      );

      // Should not throw even when processing fails
      await expectLater(workerWithTimeout.start(), completes);

      verify(mockDriver.process()).called(greaterThan(0));
    });

    test('should respect maxJobs limit', () async {
      int processCount = 0;
      when(mockDriver.process()).thenAnswer((_) async {
        processCount++;
        if (processCount >= 3) {
          // Stop the worker by throwing an exception that will be caught
          throw Exception('Stop worker');
        }
      });

      final workerWithLimit = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(maxJobs: 2),
      );

      await expectLater(workerWithLimit.start(), completes);

      // Should have processed exactly maxJobs times
      verify(mockDriver.process()).called(2);
    });

    test('should respect timeout', () async {
      when(mockDriver.process()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
      });

      final workerWithTimeout = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(
          timeout: Duration(milliseconds: 50),
          delay: Duration.zero, // No delay between processing
        ),
      );

      final startTime = DateTime.now();
      await workerWithTimeout.start();
      final endTime = DateTime.now();

      // Should have stopped within a reasonable time after timeout
      expect(endTime.difference(startTime).inMilliseconds, lessThan(150));
    });

    test('should use custom delay between processing', () async {
      when(mockDriver.process()).thenAnswer((_) async {
        // Fast processing
      });

      final workerWithDelay = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(
          maxJobs: 3,
          delay: Duration(milliseconds: 50),
        ),
      );

      final startTime = DateTime.now();
      await workerWithDelay.start();
      final endTime = DateTime.now();

      // Should have taken at least the delay time
      expect(endTime.difference(startTime).inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('should run in background when configured', () async {
      when(mockDriver.process()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
      });

      final workerBackground = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(
          runInBackground: true,
          maxJobs: 1,
          timeout: Duration(milliseconds: 50),
        ),
      );

      // Start should return immediately for background workers
      final startTime = DateTime.now();
      await workerBackground.start();
      final endTime = DateTime.now();

      // Should return quickly
      expect(endTime.difference(startTime).inMilliseconds, lessThan(20));
    });

    test('should call error callback on processing errors', () async {
      Exception? capturedError;
      StackTrace? capturedStack;

      when(mockDriver.process()).thenThrow(Exception('Processing failed'));

      final workerWithCallback = QueueWorker(
        mockDriver,
        QueueWorkerConfig(
          maxJobs: 1,
          timeout: const Duration(milliseconds: 50),
          onError: (error, stack) {
            capturedError = error as Exception?;
            capturedStack = stack;
          },
        ),
      );

      await workerWithCallback.start();

      expect(capturedError, isNotNull);
      expect(capturedError!.toString(), contains('Processing failed'));
      expect(capturedStack, isNotNull);
    });

    test('should handle worker configuration edge cases', () {
      // Test with null values
      final workerWithNulls = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(
          maxJobs: null,
          delay: Duration.zero,
          timeout: null,
          runInBackground: false,
        ),
      );

      expect(workerWithNulls, isNotNull);
    });

    test('should handle very short delays', () async {
      when(mockDriver.process()).thenAnswer((_) async {
        // Very fast processing
      });

      final workerFast = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(
          maxJobs: 5,
          delay: Duration.zero,
        ),
      );

      await expectLater(workerFast.start(), completes);

      verify(mockDriver.process()).called(5);
    });

    test('should handle very long delays', () async {
      when(mockDriver.process()).thenAnswer((_) async {
        // Fast processing
      });

      final workerSlow = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(
          maxJobs: 2,
          delay: Duration(seconds: 1),
        ),
      );

      final startTime = DateTime.now();
      await workerSlow.start();
      final endTime = DateTime.now();

      // Should have taken at least the delay time
      expect(endTime.difference(startTime).inMilliseconds, greaterThanOrEqualTo(1000));
    });

    test('should handle zero timeout', () async {
      when(mockDriver.process()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
      });

      final workerZeroTimeout = QueueWorker(
        mockDriver,
        const QueueWorkerConfig(timeout: Duration.zero),
      );

      final startTime = DateTime.now();
      await workerZeroTimeout.start();
      final endTime = DateTime.now();

      // Should stop immediately due to zero timeout
      expect(endTime.difference(startTime).inMilliseconds, lessThan(50));
    });

    test('should handle concurrent worker starts', () async {
      when(mockDriver.process()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
      });

      final workers = List.generate(3, (_) => QueueWorker(
        mockDriver,
        const QueueWorkerConfig(maxJobs: 1, timeout: Duration(milliseconds: 50)),
      ));

      // Start all workers concurrently
      await Future.wait(workers.map((w) => w.start()));

      // All should complete
      verify(mockDriver.process()).called(greaterThanOrEqualTo(3));
    });
  });

  group('QueueWorkerConfig', () {
    test('should create config with default values', () {
      const config = QueueWorkerConfig();

      expect(config.maxJobs, isNull);
      expect(config.delay, equals(const Duration(seconds: 1)));
      expect(config.timeout, isNull);
      expect(config.runInBackground, isFalse);
      expect(config.onError, isNull);
      expect(config.onJobStart, isNull);
      expect(config.onJobComplete, isNull);
      expect(config.onJobError, isNull);
    });

    test('should create config with custom values', () {
      final config = QueueWorkerConfig(
        maxJobs: 10,
        delay: const Duration(milliseconds: 500),
        timeout: const Duration(minutes: 5),
        runInBackground: true,
        onError: (error, stack) {},
        onJobStart: (job) {},
        onJobComplete: (job, result) {},
        onJobError: (job, error, stack) {},
      );

      expect(config.maxJobs, equals(10));
      expect(config.delay, equals(const Duration(milliseconds: 500)));
      expect(config.timeout, equals(const Duration(minutes: 5)));
      expect(config.runInBackground, isTrue);
      expect(config.onError, isNotNull);
      expect(config.onJobStart, isNotNull);
      expect(config.onJobComplete, isNotNull);
      expect(config.onJobError, isNotNull);
    });

    test('should handle const constructor', () {
      const config = QueueWorkerConfig(
        maxJobs: 5,
        delay: Duration(seconds: 2),
        timeout: Duration(minutes: 1),
        runInBackground: true,
      );

      expect(config.maxJobs, equals(5));
      expect(config.delay, equals(const Duration(seconds: 2)));
      expect(config.timeout, equals(const Duration(minutes: 1)));
      expect(config.runInBackground, isTrue);
    });
  });
}
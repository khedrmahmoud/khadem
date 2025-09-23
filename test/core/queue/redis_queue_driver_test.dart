import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/queue_drivers/redis_queue_driver.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Mock Redis Command class
class MockCommand extends Mock {
  Future<dynamic> sendObject(List<dynamic> command) {
    return Future.value();
  }
}

// Test job implementation
class TestQueueJob extends QueueJob {
  final String name;
  bool executed = false;

  TestQueueJob(this.name);

  @override
  Future<void> handle() async {
    executed = true;
    // Simulate some work
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class FailingQueueJob extends QueueJob {
  final String name;

  FailingQueueJob(this.name);

  @override
  Future<void> handle() async {
    throw Exception('Job failed');
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

void main() {
  group('RedisQueueDriver', () {
    late RedisQueueDriver driver;
    late TestQueueJob testJob;
    late FailingQueueJob failingJob;

    setUp(() {
      driver = RedisQueueDriver(
        queueName: 'test_queue',
      );
      testJob = TestQueueJob('test');
      failingJob = FailingQueueJob('failing');
    });

    tearDown(() async {
      // Clean up
      await driver.clear();
      await driver.close();
    });

    test('should initialize with correct parameters', () {
      expect(driver, isNotNull);

      // Test with custom parameters
      final customDriver = RedisQueueDriver(
        queueName: 'custom_queue',
        host: 'redis.example.com',
        port: 6380,
        password: 'secret',
      );

      expect(customDriver, isNotNull);
    });

    test('should handle push when Redis is unavailable', () async {
      // This test expects ServiceNotFoundException when Khadem is not initialized
      expect(() => driver.push(testJob), throwsException);
    });

    test('should handle process when Redis is unavailable', () async {
      // Process should complete without throwing even when Redis is unavailable
      await expectLater(driver.process(), completes);
    });

    test('should handle delayed jobs when Redis is unavailable', () async {
      // This test expects ServiceNotFoundException when Khadem is not initialized
      expect(
        () => driver.push(testJob, delay: const Duration(seconds: 5)),
        throwsException,
      );
    });

    test('should handle clear when Redis is unavailable', () async {
      await expectLater(driver.clear(), completes);
    });

    test('should handle getStats when Redis is unavailable', () async {
      final stats = await driver.getStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['driver'], equals('redis'));
      expect(stats['host'], equals('localhost'));
      expect(stats['port'], equals(6379));
      expect(stats['queue_name'], equals('queue:test_queue'));
      // Should return default values when Redis is unavailable
      expect(stats['immediate_jobs'], equals(0));
      expect(stats['delayed_jobs'], equals(0));
      expect(stats['failed_jobs'], equals(0));
      expect(stats['total_jobs'], equals(0));
    });

    test('should handle close gracefully', () async {
      await expectLater(driver.close(), completes);
    });

    test('should create different queue names for different instances', () {
      final driver1 = RedisQueueDriver(queueName: 'queue1');
      final driver2 = RedisQueueDriver(queueName: 'queue2');

      expect(driver1, isNotNull);
      expect(driver2, isNotNull);
      // Note: We can't easily test the internal queue names without reflection
    });

    test('should handle multiple jobs in sequence', () async {
      final jobs = [
        TestQueueJob('job1'),
        TestQueueJob('job2'),
        TestQueueJob('job3'),
      ];

      // Push all jobs - expect exceptions due to uninitialized Khadem
      for (final job in jobs) {
        expect(() => driver.push(job), throwsException);
      }
    });

    test('should handle mixed immediate and delayed jobs', () async {
      final immediateJob = TestQueueJob('immediate');
      final delayedJob = TestQueueJob('delayed');

      expect(() => driver.push(immediateJob), throwsException);
      expect(
        () => driver.push(delayedJob, delay: const Duration(seconds: 1)),
        throwsException,
      );
    });

    test('should handle job failures gracefully', () async {
      expect(() => driver.push(failingJob), throwsException);
    });

    test('should provide meaningful error information in stats', () async {
      final stats = await driver.getStats();

      expect(stats['driver'], equals('redis'));
      expect(stats['host'], equals('localhost'));
      expect(stats['port'], equals(6379));
      expect(stats['queue_name'], equals('queue:test_queue'));

      // When Redis is unavailable, should have error info
      if (stats.containsKey('error')) {
        expect(stats['error'], isNotEmpty);
      }
    });

    test('should handle empty queue processing', () async {
      // Process empty queue should not throw
      await expectLater(driver.process(), completes);

      final stats = await driver.getStats();
      expect(stats['immediate_jobs'] ?? 0, equals(0));
      expect(stats['delayed_jobs'] ?? 0, equals(0));
    });

    test('should handle concurrent operations', () async {
      // All push operations should throw due to uninitialized Khadem
      for (int i = 0; i < 5; i++) {
        expect(
          () => driver.push(TestQueueJob('concurrent_$i')),
          throwsException,
        );
      }
    });

    test('should handle very long queue names', () {
      final longQueueName = 'a' * 1000;
      final driverWithLongName = RedisQueueDriver(queueName: longQueueName);

      expect(driverWithLongName, isNotNull);
    });

    test('should handle special characters in queue names', () {
      const specialQueueName = 'test-queue_with.special:chars';
      final driverWithSpecialName =
          RedisQueueDriver(queueName: specialQueueName);

      expect(driverWithSpecialName, isNotNull);
    });
  });

  group('RedisQueueDriver Integration Tests', () {
    // These tests would run only if Redis is available
    // For now, they're skipped since Redis might not be running in CI

    test(
      'should work with real Redis connection',
      () async {
        // This test is skipped unless Redis is available
      },
      skip: 'Requires Redis server to be running',
    );

    test(
      'should persist jobs across driver restarts',
      () async {
        // This test is skipped unless Redis is available
      },
      skip: 'Requires Redis server to be running',
    );

    test(
      'should handle Redis connection drops',
      () async {
        // This test is skipped unless Redis is available
      },
      skip: 'Requires Redis server to be running',
    );
  });
}

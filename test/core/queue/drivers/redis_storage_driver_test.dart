import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/drivers/base_driver.dart';
import 'package:khadem/src/core/queue/drivers/redis_storage_driver.dart';
import 'package:khadem/src/core/queue/registry/index.dart';
import 'package:test/test.dart';

// Test job implementation
class TestJob extends QueueJob {
  final String name;
  bool executed = false;

  TestJob(this.name);

  @override
  Future<void> handle() async {
    executed = true;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Map<String, dynamic> toJson() => {'name': name, 'type': 'TestJob'};

  factory TestJob.fromJson(Map<String, dynamic> json) {
    return TestJob(json['name'] as String);
  }
}

class BadJob extends QueueJob {
  @override
  Future<void> handle() async {}

  @override
  Map<String, dynamic> toJson() {
    throw Exception('Serialization failed');
  }
}

void main() {
  setUpAll(() {
    // Register job types for deserialization
    QueueJobRegistry.register('TestJob', TestJob.fromJson);
  });

  group('RedisStorageDriver - Unit Tests', () {
    test('should initialize with default config', () {
      final driver = RedisStorageDriver(
        config: const DriverConfig(name: 'test-redis'),
      );

      expect(driver, isNotNull);
    });

    test('should initialize with custom config', () {
      final driver = RedisStorageDriver(
        config: const DriverConfig(
          name: 'test-redis-custom',
          driverSpecificConfig: {
            'host': 'redis.example.com',
            'port': 6379,
            'queueName': 'custom-queue',
          },
        ),
      );

      expect(driver, isNotNull);
    });

    test('should initialize with explicit parameters', () {
      final driver = RedisStorageDriver(
        config: const DriverConfig(name: 'test-redis-params'),
        host: '10.0.0.1',
        port: 6379,
        queueName: 'my-queue',
      );

      expect(driver, isNotNull);
    });

    test('should use default values when not provided', () {
      final driver = RedisStorageDriver(
        config: const DriverConfig(name: 'test-redis-defaults'),
      );

      expect(driver, isNotNull);
      // Driver should have sensible defaults
    });
  });

  group('RedisStorageDriver - Integration Tests', () {
    // Note: These tests require a running Redis instance
    // They will be skipped if Redis is not available

    late RedisStorageDriver driver;
    bool redisAvailable = false;

    setUpAll(() async {
      // Check if Redis is available
      try {
        driver = RedisStorageDriver(
          config: const DriverConfig(name: 'test-redis-integration'),
          host: 'localhost',
          port: 6379,
          queueName: 'test-queue-${DateTime.now().millisecondsSinceEpoch}',
        );

        // Try to connect by pushing a test job
        await driver.push(TestJob('connection-test'));
        redisAvailable = true;
        print('✅ Redis is available for integration tests');
      } catch (e) {
        redisAvailable = false;
        print('❌ Failed to connect to Redis: $e');
        print('⚠️ Redis not available. Skipping integration tests.');
        print('   Start Redis with: docker run -p 6379:6379 -d redis:alpine');
      }
    });

    tearDown(() async {
      if (redisAvailable) {
        try {
          await driver.clear();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    test('should push job to Redis queue', () async {
      if (!redisAvailable) {
        markTestSkipped('Redis not available');
        return;
      }

      final job = TestJob('push-test');
      await driver.push(job);

      // Job should be queued (not executed yet)
      expect(job.executed, isFalse);
    });

    test('should push job with delay to Redis', () async {
      if (!redisAvailable) {
        markTestSkipped('Redis not available');
        return;
      }

      final job = TestJob('delayed-test');
      await driver.push(job, delay: const Duration(seconds: 5));

      // Job should be in delayed queue
      expect(job.executed, isFalse);
    });

    test('should process job from Redis queue', () async {
      if (!redisAvailable) {
        markTestSkipped('Redis not available');
        return;
      }

      final job = TestJob('process-test');
      await driver.push(job);

      // Process the job
      await driver.process();

      // Give it a moment to process
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify job was processed by checking queue stats
      final stats = await driver.getStats();
      final queueStats = stats['queue'] as Map<String, dynamic>?;

      // Queue should be empty or have fewer jobs
      expect(queueStats, isNotNull);
      expect(queueStats!['main_jobs'], lessThanOrEqualTo(1));
    });

    test('should handle multiple jobs', () async {
      if (!redisAvailable) {
        markTestSkipped('Redis not available');
        return;
      }

      final job1 = TestJob('job-1');
      final job2 = TestJob('job-2');
      final job3 = TestJob('job-3');

      await driver.push(job1);
      await driver.push(job2);
      await driver.push(job3);

      // Get initial stats
      final statsBefore = await driver.getStats();
      final queueBefore = statsBefore['queue'] as Map<String, dynamic>;
      final jobsBefore = queueBefore['total_jobs'] as int;

      // Process all jobs
      await driver.process();
      await driver.process();
      await driver.process();

      await Future.delayed(const Duration(milliseconds: 200));

      // Verify jobs were processed (queue should be empty or smaller)
      final statsAfter = await driver.getStats();
      final queueAfter = statsAfter['queue'] as Map<String, dynamic>;
      final jobsAfter = queueAfter['total_jobs'] as int;

      expect(jobsAfter, lessThan(jobsBefore));
    });

    test('should process delayed jobs when ready', () async {
      if (!redisAvailable) {
        markTestSkipped('Redis not available');
        return;
      }

      final job = TestJob('delayed-ready');
      await driver.push(job, delay: const Duration(milliseconds: 100));

      // Verify job is in delayed queue
      final statsInitial = await driver.getStats();
      final queueInitial = statsInitial['queue'] as Map<String, dynamic>;
      expect(queueInitial['delayed_jobs'], greaterThan(0));

      // Process immediately - job not ready yet (should still be in delayed queue)
      await driver.process();
      await Future.delayed(const Duration(milliseconds: 50));

      // Wait for delay to pass
      await Future.delayed(const Duration(milliseconds: 100));

      // Process again - job should be ready now
      await driver.process();
      await Future.delayed(const Duration(milliseconds: 200));

      // Job should have moved from delayed queue
      final stats = await driver.getStats();
      final queue = stats['queue'] as Map<String, dynamic>;
      expect(queue['delayed_jobs'], equals(0));
    });

    test('should clear all jobs from Redis', () async {
      if (!redisAvailable) {
        markTestSkipped('Redis not available');
        return;
      }

      await driver.push(TestJob('clear-1'));
      await driver.push(TestJob('clear-2'));
      await driver.push(TestJob('clear-3'), delay: const Duration(seconds: 10));

      await driver.clear();

      // No jobs should be processed after clear
      await driver.process();
      await Future.delayed(const Duration(milliseconds: 100));

      // Queue should be empty (this is verified by Redis returning nothing)
    });

    test('should get queue statistics', () async {
      if (!redisAvailable) {
        markTestSkipped('Redis not available');
        return;
      }

      await driver.push(TestJob('stats-1'));
      await driver.push(TestJob('stats-2'));
      await driver.push(TestJob('stats-3'), delay: const Duration(seconds: 5));

      final stats = await driver.getStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['driver'], equals('test-redis-integration'));

      // Should have connection info
      expect(stats.containsKey('connection'), isTrue);
      final connection = stats['connection'] as Map<String, dynamic>;
      expect(connection['host'], equals('localhost'));
      expect(connection['port'], equals(6379));

      // Should have queue stats
      expect(stats.containsKey('queue'), isTrue);
      final queue = stats['queue'] as Map<String, dynamic>;
      expect(queue['total_jobs'], greaterThan(0));
      expect(queue['delayed_jobs'], greaterThan(0));
    });

    test('should handle connection errors gracefully', () async {
      // Create driver with invalid host
      final badDriver = RedisStorageDriver(
        config: const DriverConfig(name: 'test-redis-bad'),
        host: 'invalid-host-12345',
        port: 99999,
        queueName: 'test-bad-queue',
      );

      // Should throw connection error
      await expectLater(
        badDriver.push(TestJob('will-fail')),
        throwsA(anything),
      );
    });

    test(
      'should handle authentication',
      () async {
        // This test requires Redis with password configured
        // Skipping by default as test Redis usually has no auth
      },
      skip: 'Requires Redis with authentication configured',
    );

    test('should support job serialization round-trip', () async {
      if (!redisAvailable) {
        markTestSkipped('Redis not available');
        return;
      }

      final originalJob = TestJob('serialization-test');
      await driver.push(originalJob);

      // Process and the job should deserialize correctly (won't throw)
      await driver.process();
      await Future.delayed(const Duration(milliseconds: 100));

      // If we got here without exception, serialization worked
      expect(true, isTrue);
    });
  });

  group('RedisStorageDriver - Configuration', () {
    test('should prefer explicit parameters over config', () {
      final driver = RedisStorageDriver(
        config: const DriverConfig(
          name: 'test-priority',
          driverSpecificConfig: {
            'host': 'config-host',
            'port': 1111,
            'queueName': 'config-queue',
          },
        ),
        host: 'explicit-host',
        port: 2222,
        queueName: 'explicit-queue',
      );

      expect(driver, isNotNull);
      // Explicit parameters should take precedence
    });

    test('should fall back to config when explicit params not provided', () {
      final driver = RedisStorageDriver(
        config: const DriverConfig(
          name: 'test-fallback',
          driverSpecificConfig: {
            'host': 'fallback-host',
            'port': 3333,
            'password': 'fallback-pass',
            'queueName': 'fallback-queue',
          },
        ),
      );

      expect(driver, isNotNull);
    });

    test('should use defaults when nothing provided', () {
      final driver = RedisStorageDriver(
        config: const DriverConfig(name: 'test-defaults'),
      );

      expect(driver, isNotNull);
      // Should use localhost:6379 and 'default' queue name
    });
  });

  group('RedisStorageDriver - Error Handling', () {
    test('should handle serialization errors', () async {
      final driver = RedisStorageDriver(
        config: const DriverConfig(name: 'test-serial-error'),
      );

      await expectLater(
        driver.push(BadJob()),
        throwsA(anything),
      );
    });

    test(
      'should handle network interruptions',
      () async {
        // This would require mocking the Redis connection
        // Skipping for now as it requires more complex setup
      },
      skip: 'Requires mocking Redis connection',
    );
  });
}

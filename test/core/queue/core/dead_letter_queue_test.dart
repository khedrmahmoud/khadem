import 'package:khadem/src/contracts/queue/dlq/index.dart';
import 'package:khadem/src/core/queue/dlq/index.dart';
import 'package:test/test.dart';

void main() {
  group('FailedJob', () {
    test('should create a failed job with all required fields', () {
      final failedJob = FailedJob(
        id: 'job-123',
        jobType: 'SendEmailJob',
        payload: {'email': 'test@example.com'},
        error: 'Connection timeout',
        stackTrace: 'Stack trace here...',
        failedAt: DateTime(2025, 10, 25, 10, 30),
        attempts: 3,
        metadata: {'queue': 'emails'},
      );

      expect(failedJob.id, equals('job-123'));
      expect(failedJob.jobType, equals('SendEmailJob'));
      expect(failedJob.payload['email'], equals('test@example.com'));
      expect(failedJob.error, equals('Connection timeout'));
      expect(failedJob.stackTrace, equals('Stack trace here...'));
      expect(failedJob.failedAt, equals(DateTime(2025, 10, 25, 10, 30)));
      expect(failedJob.attempts, equals(3));
      expect(failedJob.metadata['queue'], equals('emails'));
    });

    test('should create a failed job without optional fields', () {
      final failedJob = FailedJob(
        id: 'job-456',
        jobType: 'ProcessPaymentJob',
        payload: {'amount': 100},
        error: 'Payment failed',
        failedAt: DateTime(2025, 10, 25),
        attempts: 1,
      );

      expect(failedJob.stackTrace, isNull);
      expect(failedJob.metadata, isEmpty);
    });

    test('should serialize to JSON correctly', () {
      final failedJob = FailedJob(
        id: 'job-789',
        jobType: 'NotificationJob',
        payload: {'userId': '123'},
        error: 'User not found',
        stackTrace: 'at line 42...',
        failedAt: DateTime(2025, 10, 25, 12),
        attempts: 2,
        metadata: {'priority': 'high'},
      );

      final json = failedJob.toJson();

      expect(json['id'], equals('job-789'));
      expect(json['jobType'], equals('NotificationJob'));
      expect(json['payload'], equals({'userId': '123'}));
      expect(json['error'], equals('User not found'));
      expect(json['stackTrace'], equals('at line 42...'));
      expect(json['failedAt'], equals('2025-10-25T12:00:00.000'));
      expect(json['attempts'], equals(2));
      expect(json['metadata'], equals({'priority': 'high'}));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'job-999',
        'jobType': 'BackupJob',
        'payload': {'database': 'main'},
        'error': 'Disk full',
        'stackTrace': 'Error stack...',
        'failedAt': '2025-10-25T15:30:00.000',
        'attempts': 5,
        'metadata': {'server': 'prod-1'},
      };

      final failedJob = FailedJob.fromJson(json);

      expect(failedJob.id, equals('job-999'));
      expect(failedJob.jobType, equals('BackupJob'));
      expect(failedJob.payload['database'], equals('main'));
      expect(failedJob.error, equals('Disk full'));
      expect(failedJob.stackTrace, equals('Error stack...'));
      expect(failedJob.failedAt, equals(DateTime(2025, 10, 25, 15, 30)));
      expect(failedJob.attempts, equals(5));
      expect(failedJob.metadata['server'], equals('prod-1'));
    });

    test('should handle JSON without optional fields', () {
      final json = {
        'id': 'job-111',
        'jobType': 'CleanupJob',
        'payload': {'files': 10},
        'error': 'Permission denied',
        'failedAt': '2025-10-25T09:00:00.000',
        'attempts': 1,
      };

      final failedJob = FailedJob.fromJson(json);

      expect(failedJob.stackTrace, isNull);
      expect(failedJob.metadata, isEmpty);
    });

    test('should have meaningful toString representation', () {
      final failedJob = FailedJob(
        id: 'job-abc',
        jobType: 'TestJob',
        payload: {},
        error: 'Test error',
        failedAt: DateTime(2025, 10, 25),
        attempts: 1,
      );

      final str = failedJob.toString();

      expect(str, contains('job-abc'));
      expect(str, contains('TestJob'));
      expect(str, contains('Test error'));
      expect(str, contains('attempts: 1'));
    });

    test('should round-trip JSON serialization', () {
      final original = FailedJob(
        id: 'job-round-trip',
        jobType: 'RoundTripJob',
        payload: {
          'key': 'value',
          'nested': {'data': 123},
        },
        error: 'Round trip test',
        stackTrace: 'Stack...',
        failedAt: DateTime(2025, 10, 25, 14, 45, 30),
        attempts: 7,
        metadata: {'tag': 'test', 'version': 2},
      );

      final json = original.toJson();
      final restored = FailedJob.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.jobType, equals(original.jobType));
      expect(restored.payload, equals(original.payload));
      expect(restored.error, equals(original.error));
      expect(restored.stackTrace, equals(original.stackTrace));
      expect(restored.failedAt, equals(original.failedAt));
      expect(restored.attempts, equals(original.attempts));
      expect(restored.metadata, equals(original.metadata));
    });
  });

  group('InMemoryDeadLetterQueue', () {
    late InMemoryDeadLetterQueue dlq;

    setUp(() {
      dlq = InMemoryDeadLetterQueue();
    });

    test('should start empty', () async {
      expect(await dlq.count(), equals(0));
      expect(await dlq.getAll(), isEmpty);
    });

    test('should store a failed job', () async {
      final job = FailedJob(
        id: 'job-1',
        jobType: 'EmailJob',
        payload: {'to': 'test@example.com'},
        error: 'SMTP timeout',
        failedAt: DateTime.now(),
        attempts: 1,
      );

      await dlq.store(job);

      expect(await dlq.count(), equals(1));
      final retrieved = await dlq.get('job-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('job-1'));
    });

    test('should retrieve a stored job by ID', () async {
      final job = FailedJob(
        id: 'job-retrieve',
        jobType: 'TestJob',
        payload: {'data': 'test'},
        error: 'Test error',
        failedAt: DateTime.now(),
        attempts: 1,
      );

      await dlq.store(job);

      final retrieved = await dlq.get('job-retrieve');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('job-retrieve'));
      expect(retrieved.error, equals('Test error'));
    });

    test('should return null for non-existent job', () async {
      final retrieved = await dlq.get('non-existent');
      expect(retrieved, isNull);
    });

    test('should get all failed jobs', () async {
      final job1 = FailedJob(
        id: 'job-1',
        jobType: 'Job1',
        payload: {},
        error: 'Error 1',
        failedAt: DateTime.now(),
        attempts: 1,
      );

      final job2 = FailedJob(
        id: 'job-2',
        jobType: 'Job2',
        payload: {},
        error: 'Error 2',
        failedAt: DateTime.now(),
        attempts: 2,
      );

      await dlq.store(job1);
      await dlq.store(job2);

      final all = await dlq.getAll();
      expect(all.length, equals(2));
      expect(all.map((j) => j.id).toList(), containsAll(['job-1', 'job-2']));
    });

    test('should respect limit when getting all jobs', () async {
      for (int i = 1; i <= 10; i++) {
        await dlq.store(
          FailedJob(
            id: 'job-$i',
            jobType: 'TestJob',
            payload: {},
            error: 'Error $i',
            failedAt: DateTime.now(),
            attempts: 1,
          ),
        );
      }

      final limited = await dlq.getAll(limit: 5);
      expect(limited.length, equals(5));
    });

    test('should support offset when getting all jobs', () async {
      for (int i = 1; i <= 10; i++) {
        await dlq.store(
          FailedJob(
            id: 'job-$i',
            jobType: 'TestJob',
            payload: {},
            error: 'Error $i',
            failedAt: DateTime.now(),
            attempts: 1,
          ),
        );
      }

      final offset = await dlq.getAll(offset: 5);
      expect(offset.length, equals(5));
    });

    test('should filter jobs by type', () async {
      await dlq.store(
        FailedJob(
          id: 'email-1',
          jobType: 'EmailJob',
          payload: {},
          error: 'Error',
          failedAt: DateTime.now(),
          attempts: 1,
        ),
      );

      await dlq.store(
        FailedJob(
          id: 'email-2',
          jobType: 'EmailJob',
          payload: {},
          error: 'Error',
          failedAt: DateTime.now(),
          attempts: 1,
        ),
      );

      await dlq.store(
        FailedJob(
          id: 'payment-1',
          jobType: 'PaymentJob',
          payload: {},
          error: 'Error',
          failedAt: DateTime.now(),
          attempts: 1,
        ),
      );

      final emailJobs = await dlq.getByType('EmailJob');
      expect(emailJobs.length, equals(2));
      expect(emailJobs.every((j) => j.jobType == 'EmailJob'), isTrue);

      final paymentJobs = await dlq.getByType('PaymentJob');
      expect(paymentJobs.length, equals(1));
    });

    test('should filter jobs by date range', () async {
      final date1 = DateTime(2025, 10, 20);
      final date2 = DateTime(2025, 10, 25);
      final date3 = DateTime(2025, 10, 30);

      await dlq.store(
        FailedJob(
          id: 'old-job',
          jobType: 'TestJob',
          payload: {},
          error: 'Error',
          failedAt: date1,
          attempts: 1,
        ),
      );

      await dlq.store(
        FailedJob(
          id: 'current-job',
          jobType: 'TestJob',
          payload: {},
          error: 'Error',
          failedAt: date2,
          attempts: 1,
        ),
      );

      await dlq.store(
        FailedJob(
          id: 'future-job',
          jobType: 'TestJob',
          payload: {},
          error: 'Error',
          failedAt: date3,
          attempts: 1,
        ),
      );

      final rangeJobs = await dlq.getByDateRange(
        DateTime(2025, 10, 22),
        DateTime(2025, 10, 28),
      );

      expect(rangeJobs.length, equals(1));
      expect(rangeJobs.first.id, equals('current-job'));
    });

    test('should remove a failed job', () async {
      final job = FailedJob(
        id: 'job-remove',
        jobType: 'TestJob',
        payload: {},
        error: 'Error',
        failedAt: DateTime.now(),
        attempts: 1,
      );

      await dlq.store(job);
      expect(await dlq.count(), equals(1));

      await dlq.remove('job-remove');
      expect(await dlq.count(), equals(0));
      expect(await dlq.get('job-remove'), isNull);
    });

    test('should clear all failed jobs', () async {
      for (int i = 1; i <= 5; i++) {
        await dlq.store(
          FailedJob(
            id: 'job-$i',
            jobType: 'TestJob',
            payload: {},
            error: 'Error $i',
            failedAt: DateTime.now(),
            attempts: 1,
          ),
        );
      }

      expect(await dlq.count(), equals(5));

      await dlq.clear();

      expect(await dlq.count(), equals(0));
      expect(await dlq.getAll(), isEmpty);
    });

    test('should get statistics', () async {
      await dlq.store(
        FailedJob(
          id: 'job-1',
          jobType: 'EmailJob',
          payload: {},
          error: 'Error',
          failedAt: DateTime.now(),
          attempts: 1,
        ),
      );

      await dlq.store(
        FailedJob(
          id: 'job-2',
          jobType: 'EmailJob',
          payload: {},
          error: 'Error',
          failedAt: DateTime.now(),
          attempts: 3,
        ),
      );

      await dlq.store(
        FailedJob(
          id: 'job-3',
          jobType: 'PaymentJob',
          payload: {},
          error: 'Error',
          failedAt: DateTime.now(),
          attempts: 2,
        ),
      );

      final stats = await dlq.getStats();

      expect(stats['total'], equals(3));
      expect(stats['byType'], isA<Map>());
      expect(stats['byType']['EmailJob'], equals(2));
      expect(stats['byType']['PaymentJob'], equals(1));
    });

    test('should handle concurrent operations', () async {
      final futures = <Future>[];

      for (int i = 1; i <= 100; i++) {
        futures.add(
          dlq.store(
            FailedJob(
              id: 'job-$i',
              jobType: 'TestJob',
              payload: {},
              error: 'Error $i',
              failedAt: DateTime.now(),
              attempts: 1,
            ),
          ),
        );
      }

      await Future.wait(futures);

      expect(await dlq.count(), equals(100));
    });
  });

  group('FileDLQ', () {
    // Note: FileDLQ tests would require file system operations
    // and are similar to InMemoryDLQ but with persistence
    // Skipping for now as they would need temporary directories
  });
}

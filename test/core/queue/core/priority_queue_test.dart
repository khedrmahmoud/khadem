import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/priority/index.dart';
import 'package:test/test.dart';

class TestJob extends QueueJob {
  final String name;

  TestJob(this.name);

  @override
  Future<void> handle() async {}

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

void main() {
  group('JobPriority', () {
    test('should have correct priority values', () {
      expect(JobPriority.low.value, equals(0));
      expect(JobPriority.normal.value, equals(1));
      expect(JobPriority.high.value, equals(2));
      expect(JobPriority.critical.value, equals(3));
    });

    test('should compare priorities correctly', () {
      expect(JobPriority.critical.isHigherThan(JobPriority.high), isTrue);
      expect(JobPriority.high.isHigherThan(JobPriority.normal), isTrue);
      expect(JobPriority.normal.isHigherThan(JobPriority.low), isTrue);

      expect(JobPriority.low.isLowerThan(JobPriority.normal), isTrue);
      expect(JobPriority.normal.isLowerThan(JobPriority.high), isTrue);
      expect(JobPriority.high.isLowerThan(JobPriority.critical), isTrue);
    });

    test('should not be higher than itself', () {
      expect(JobPriority.normal.isHigherThan(JobPriority.normal), isFalse);
    });

    test('should not be lower than itself', () {
      expect(JobPriority.normal.isLowerThan(JobPriority.normal), isFalse);
    });
  });

  group('PrioritizedJob', () {
    test('should create prioritized job', () {
      final job = TestJob('test');
      final prioritized = PrioritizedJob(
        job: job,
        priority: JobPriority.high,
        id: 'job-1',
      );

      expect(prioritized.job, equals(job));
      expect(prioritized.priority, equals(JobPriority.high));
      expect(prioritized.id, equals('job-1'));
      expect(prioritized.queuedAt, isA<DateTime>());
    });

    test('should compare by priority first', () {
      final job1 = PrioritizedJob(
        job: TestJob('low'),
        priority: JobPriority.low,
        id: 'job-1',
      );

      final job2 = PrioritizedJob(
        job: TestJob('high'),
        priority: JobPriority.high,
        id: 'job-2',
      );

      // Higher priority should be "less than" (comes first)
      expect(job2.compareTo(job1), lessThan(0));
      expect(job1.compareTo(job2), greaterThan(0));
    });

    test('should compare by queue time for same priority', () async {
      final job1 = PrioritizedJob(
        job: TestJob('first'),
        priority: JobPriority.normal,
        id: 'job-1',
      );

      // Small delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));

      final job2 = PrioritizedJob(
        job: TestJob('second'),
        priority: JobPriority.normal,
        id: 'job-2',
      );

      // Older job should come first
      expect(job1.compareTo(job2), lessThan(0));
      expect(job2.compareTo(job1), greaterThan(0));
    });

    test('should serialize to JSON', () {
      final job = PrioritizedJob(
        job: TestJob('test'),
        priority: JobPriority.critical,
        id: 'job-json',
      );

      final json = job.toJson();

      expect(json['id'], equals('job-json'));
      expect(json['priority'], equals('critical'));
      expect(json['queuedAt'], isA<String>());
      expect(json['jobType'], contains('TestJob'));
    });

    test('should have meaningful toString', () {
      final job = PrioritizedJob(
        job: TestJob('test'),
        priority: JobPriority.high,
        id: 'job-str',
      );

      final str = job.toString();

      expect(str, contains('job-str'));
      expect(str, contains('high'));
      expect(str, contains('queuedAt'));
    });
  });

  group('PriorityQueue', () {
    late PriorityQueue<PrioritizedJob> queue;

    setUp(() {
      queue = PriorityQueue<PrioritizedJob>();
    });

    test('should start empty', () {
      expect(queue.isEmpty, isTrue);
      expect(queue.isNotEmpty, isFalse);
      expect(queue.length, equals(0));
    });

    test('should add items to queue', () {
      final job = PrioritizedJob(
        job: TestJob('test'),
        priority: JobPriority.normal,
        id: 'job-1',
      );

      queue.add(job);

      expect(queue.isEmpty, isFalse);
      expect(queue.isNotEmpty, isTrue);
      expect(queue.length, equals(1));
    });

    test('should maintain priority order', () {
      final lowJob = PrioritizedJob(
        job: TestJob('low'),
        priority: JobPriority.low,
        id: 'job-low',
      );

      final highJob = PrioritizedJob(
        job: TestJob('high'),
        priority: JobPriority.high,
        id: 'job-high',
      );

      final criticalJob = PrioritizedJob(
        job: TestJob('critical'),
        priority: JobPriority.critical,
        id: 'job-critical',
      );

      // Add in random order
      queue.add(lowJob);
      queue.add(criticalJob);
      queue.add(highJob);

      expect(queue.length, equals(3));

      // Should come out in priority order
      expect(queue.removeFirst()!.id, equals('job-critical'));
      expect(queue.removeFirst()!.id, equals('job-high'));
      expect(queue.removeFirst()!.id, equals('job-low'));
    });

    test('should maintain FIFO for same priority', () async {
      final job1 = PrioritizedJob(
        job: TestJob('first'),
        priority: JobPriority.normal,
        id: 'job-1',
      );

      await Future.delayed(const Duration(milliseconds: 10));

      final job2 = PrioritizedJob(
        job: TestJob('second'),
        priority: JobPriority.normal,
        id: 'job-2',
      );

      await Future.delayed(const Duration(milliseconds: 10));

      final job3 = PrioritizedJob(
        job: TestJob('third'),
        priority: JobPriority.normal,
        id: 'job-3',
      );

      queue.add(job2);
      queue.add(job1);
      queue.add(job3);

      // Should come out in order they were created (FIFO)
      expect(queue.removeFirst()!.id, equals('job-1'));
      expect(queue.removeFirst()!.id, equals('job-2'));
      expect(queue.removeFirst()!.id, equals('job-3'));
    });

    test('should peek without removing', () {
      final job = PrioritizedJob(
        job: TestJob('test'),
        priority: JobPriority.high,
        id: 'job-peek',
      );

      queue.add(job);

      final peeked = queue.peek();
      expect(peeked, isNotNull);
      expect(peeked!.id, equals('job-peek'));
      expect(queue.length, equals(1)); // Not removed
    });

    test('should return null when peeking empty queue', () {
      expect(queue.peek(), isNull);
    });

    test('should return null when removing from empty queue', () {
      expect(queue.removeFirst(), isNull);
    });

    test('should clear the queue', () {
      for (int i = 1; i <= 5; i++) {
        queue.add(
          PrioritizedJob(
            job: TestJob('job-$i'),
            priority: JobPriority.normal,
            id: 'job-$i',
          ),
        );
      }

      expect(queue.length, greaterThan(0));

      queue.clear();

      expect(queue.isEmpty, isTrue);
      expect(queue.length, equals(0));
    });

    test('should convert to sorted list', () {
      final lowJob = PrioritizedJob(
        job: TestJob('low'),
        priority: JobPriority.low,
        id: 'job-low',
      );

      final highJob = PrioritizedJob(
        job: TestJob('high'),
        priority: JobPriority.high,
        id: 'job-high',
      );

      final normalJob = PrioritizedJob(
        job: TestJob('normal'),
        priority: JobPriority.normal,
        id: 'job-normal',
      );

      queue.add(lowJob);
      queue.add(normalJob);
      queue.add(highJob);

      final list = queue.toList();

      expect(list.length, equals(3));
      expect(list[0].id, equals('job-high'));
      expect(list[1].id, equals('job-normal'));
      expect(list[2].id, equals('job-low'));
    });

    test('should handle large number of jobs', () {
      for (int i = 1; i <= 1000; i++) {
        final priority = i % 2 == 0 ? JobPriority.high : JobPriority.low;
        queue.add(
          PrioritizedJob(
            job: TestJob('job-$i'),
            priority: priority,
            id: 'job-$i',
          ),
        );
      }

      expect(queue.length, greaterThan(0));

      // All high priority jobs should come first
      int highCount = 0;
      int lowCount = 0;
      bool seenLow = false;

      while (queue.isNotEmpty) {
        final job = queue.removeFirst()!;
        if (job.priority == JobPriority.high) {
          highCount++;
          expect(
            seenLow,
            isFalse,
            reason: 'High priority job found after low priority job',
          );
        } else {
          lowCount++;
          seenLow = true;
        }
      }

      // At least some jobs should be processed
      expect(highCount, greaterThan(0));
      expect(lowCount, greaterThan(0));
    });

    test('should handle mixed priorities correctly', () {
      // Create jobs with all priority levels
      for (int i = 0; i < 20; i++) {
        const priorities = JobPriority.values;
        final priority = priorities[i % priorities.length];

        queue.add(
          PrioritizedJob(
            job: TestJob('job-$i'),
            priority: priority,
            id: 'job-$i',
          ),
        );
      }

      JobPriority? lastPriority;
      while (queue.isNotEmpty) {
        final job = queue.removeFirst()!;

        if (lastPriority != null) {
          // Current priority should be <= last priority
          expect(job.priority.value, lessThanOrEqualTo(lastPriority.value));
        }

        lastPriority = job.priority;
      }
    });
  });

  group('PriorityQueueJob Extension', () {
    test('should have default normal priority', () {
      final job = TestJob('test');
      expect(job.priority, equals(JobPriority.normal));
    });
  });
}

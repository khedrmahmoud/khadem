import 'package:test/test.dart';

import '../../../lib/src/contracts/scheduler/job_definition.dart';
import '../../../lib/src/contracts/scheduler/scheduled_job.dart';
import '../../../lib/src/core/scheduler/core/job_registry.dart';

// Mock job for testing
class TestJob implements ScheduledJob {
  @override
  final String name;

  TestJob(this.name);

  @override
  Future<void> execute() async {
    // Test implementation
  }
}

void main() {
  group('SchedulerJobRegistry', () {
    setUp(() {
      // Clear registry before each test
      SchedulerJobRegistry.clear();
    });

    tearDown(() {
      // Clean up after each test
      SchedulerJobRegistry.clear();
    });

    test('should register job successfully', () {
      final jobDef = JobDefinition(
        name: 'test_job',
        factory: (config) => TestJob('test_job'),
      );

      SchedulerJobRegistry.register(jobDef);

      expect(SchedulerJobRegistry.isRegistered('test_job'), isTrue);
      expect(SchedulerJobRegistry.registeredNames, contains('test_job'));
      expect(SchedulerJobRegistry.count, equals(1));
    });

    test('should throw error when registering duplicate job', () {
      final jobDef1 = JobDefinition(
        name: 'duplicate_job',
        factory: (config) => TestJob('duplicate_job'),
      );

      final jobDef2 = JobDefinition(
        name: 'duplicate_job',
        factory: (config) => TestJob('duplicate_job'),
      );

      SchedulerJobRegistry.register(jobDef1);
      expect(() => SchedulerJobRegistry.register(jobDef2), throwsArgumentError);
    });

    test('should resolve job correctly', () {
      final jobDef = JobDefinition(
        name: 'resolvable_job',
        factory: (config) => TestJob('resolvable_job'),
      );

      SchedulerJobRegistry.register(jobDef);

      final resolvedJob = SchedulerJobRegistry.resolve('resolvable_job', {});
      expect(resolvedJob, isNotNull);
      expect(resolvedJob?.name, equals('resolvable_job'));
    });

    test('should return null for non-existent job', () {
      final resolvedJob = SchedulerJobRegistry.resolve('nonexistent', {});
      expect(resolvedJob, isNull);
    });

    test('should unregister job', () {
      final jobDef = JobDefinition(
        name: 'unregister_job',
        factory: (config) => TestJob('unregister_job'),
      );

      SchedulerJobRegistry.register(jobDef);
      expect(SchedulerJobRegistry.isRegistered('unregister_job'), isTrue);

      final result = SchedulerJobRegistry.unregister('unregister_job');
      expect(result, isTrue);
      expect(SchedulerJobRegistry.isRegistered('unregister_job'), isFalse);
    });

    test('should return false when unregistering non-existent job', () {
      final result = SchedulerJobRegistry.unregister('nonexistent');
      expect(result, isFalse);
    });

    test('should register all built-in jobs', () {
      SchedulerJobRegistry.registerAll();

      expect(SchedulerJobRegistry.count, greaterThan(0));
      expect(SchedulerJobRegistry.isRegistered('ping'), isTrue);
      expect(SchedulerJobRegistry.isRegistered('ttl_cleaner'), isTrue);
    });

    test('should handle job factory with configuration', () {
      final jobDef = JobDefinition(
        name: 'config_job',
        factory: (config) => TestJob(config['name'] ?? 'default'),
      );

      SchedulerJobRegistry.register(jobDef);

      final job1 = SchedulerJobRegistry.resolve('config_job', {'name': 'custom'});
      final job2 = SchedulerJobRegistry.resolve('config_job', {});

      expect(job1?.name, equals('custom'));
      expect(job2?.name, equals('default'));
    });

    test('should return correct registered names', () {
      final jobDef1 = JobDefinition(
        name: 'job1',
        factory: (config) => TestJob('job1'),
      );

      final jobDef2 = JobDefinition(
        name: 'job2',
        factory: (config) => TestJob('job2'),
      );

      SchedulerJobRegistry.register(jobDef1);
      SchedulerJobRegistry.register(jobDef2);

      final names = SchedulerJobRegistry.registeredNames;
      expect(names.length, equals(2));
      expect(names, contains('job1'));
      expect(names, contains('job2'));
    });

    test('should handle empty registry', () {
      expect(SchedulerJobRegistry.count, equals(0));
      expect(SchedulerJobRegistry.registeredNames, isEmpty);
      expect(SchedulerJobRegistry.isRegistered('any'), isFalse);

      final resolved = SchedulerJobRegistry.resolve('any', {});
      expect(resolved, isNull);
    });

    test('should clear registry', () {
      final jobDef = JobDefinition(
        name: 'clear_job',
        factory: (config) => TestJob('clear_job'),
      );

      SchedulerJobRegistry.register(jobDef);
      expect(SchedulerJobRegistry.count, equals(1));

      SchedulerJobRegistry.clear();
      expect(SchedulerJobRegistry.count, equals(0));
      expect(SchedulerJobRegistry.registeredNames, isEmpty);
    });
  });
}

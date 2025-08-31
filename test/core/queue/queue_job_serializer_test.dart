import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/contracts/queue/queue_job.dart';
import '../../../lib/src/core/queue/queue_job_serializer.dart';

// Mock classes for testing
class MockQueueJob extends Mock implements QueueJob {
  @override
  String toString() => 'MockQueueJob';
}

class TestQueueJob extends QueueJob {
  final String data;

  TestQueueJob(this.data);

  @override
  Future<void> handle() async {
    // Test implementation
  }

  @override
  Map<String, dynamic> toJson() => {'data': data};

  @override
  TestQueueJob fromJson(Map<String, dynamic> json) => TestQueueJob(json['data']);
}

void main() {
  group('QueueJobSerializer', () {
    late QueueJobSerializer serializer;
    late TestQueueJob testJob;

    setUp(() {
      serializer = QueueJobSerializer();
      testJob = TestQueueJob('test data');
    });

    test('should serialize job with metadata', () {
      final json = serializer.serialize(testJob);

      expect(json['type'], equals('TestQueueJob'));
      expect(json['data'], equals('test data'));
      expect(json.containsKey('created_at'), isTrue);
    });

    test('should deserialize job correctly', () {
      serializer.registerFactory('TestQueueJob', (json) => TestQueueJob(json['data']));

      final json = serializer.serialize(testJob);
      final deserialized = serializer.deserialize(json);

      expect(deserialized, isA<TestQueueJob>());
      expect((deserialized as TestQueueJob).data, equals('test data'));
    });

    test('should throw on missing type', () {
      final json = {'data': 'test'};

      expect(() => serializer.deserialize(json), throwsA(isA<QueueSerializationException>()));
    });

    test('should throw on unregistered factory', () {
      final json = {'type': 'UnknownJob', 'data': 'test'};

      expect(() => serializer.deserialize(json), throwsA(isA<QueueSerializationException>()));
    });

    test('should throw on deserialization error', () {
      serializer.registerFactory('TestQueueJob', (json) => throw Exception('Deserialization failed'));

      final json = {'type': 'TestQueueJob', 'data': 'test'};

      expect(() => serializer.deserialize(json), throwsA(isA<QueueSerializationException>()));
    });

    test('should check factory registration', () {
      expect(serializer.hasFactory('TestQueueJob'), isFalse);

      serializer.registerFactory('TestQueueJob', (json) => TestQueueJob(json['data']));
      expect(serializer.hasFactory('TestQueueJob'), isTrue);
    });

    test('should get registered types', () {
      expect(serializer.getRegisteredTypes(), isEmpty);

      serializer.registerFactory('TestQueueJob', (json) => TestQueueJob(json['data']));
      expect(serializer.getRegisteredTypes(), contains('TestQueueJob'));
    });
  });

  group('QueueSerializationException', () {
    test('should create exception with message', () {
      final exception = QueueSerializationException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.toString(), equals('QueueSerializationException: Test error'));
    });
  });
}

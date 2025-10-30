import 'package:khadem/src/contracts/queue/queue_job.dart';
import 'package:khadem/src/core/queue/serialization/index.dart';
import 'package:test/test.dart';

// Test job using SerializableJob mixin
class EmailJob extends QueueJob with SerializableJob {
  final String email;
  final String subject;
  final String body;

  bool executed = false;

  EmailJob(this.email, this.subject, this.body);

  factory EmailJob.fromJson(Map<String, dynamic> json) {
    return EmailJob(
      json['email'] as String,
      json['subject'] as String,
      json['body'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'email': email,
        'subject': subject,
        'body': body,
      };

  @override
  Future<void> handle() async {
    executed = true;
    // Simulate email sending
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  String get displayName => 'EmailJob';
}

// Test job using SerializableQueueJob base class
class PaymentJob extends SerializableQueueJob {
  final String orderId;
  final double amount;
  final String currency;

  bool executed = false;

  PaymentJob(this.orderId, this.amount, {this.currency = 'USD'});

  factory PaymentJob.fromJson(Map<String, dynamic> json) {
    return PaymentJob(
      json['orderId'] as String,
      json['amount'] as double,
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
      };

  @override
  Future<void> handle() async {
    executed = true;
    // Simulate payment processing
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  String get displayName => 'PaymentJob';
}

// Test job with complex data types
class DataProcessingJob extends SerializableQueueJob {
  final List<String> items;
  final Map<String, dynamic> config;
  final DateTime scheduledAt;

  bool executed = false;

  DataProcessingJob(this.items, this.config, this.scheduledAt);

  factory DataProcessingJob.fromJson(Map<String, dynamic> json) {
    return DataProcessingJob(
      (json['items'] as List).cast<String>(),
      Map<String, dynamic>.from(json['config'] as Map),
      DateTime.parse(json['scheduledAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'items': items,
        'config': config,
        'scheduledAt': scheduledAt.toIso8601String(),
      };

  @override
  Future<void> handle() async {
    executed = true;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  String get displayName => 'DataProcessingJob';
}

// Test job with optional and nullable fields
class NotificationJob extends SerializableQueueJob {
  final String userId;
  final String message;
  final String? title;
  final Map<String, dynamic>? metadata;

  bool executed = false;

  NotificationJob(this.userId, this.message, {this.title, this.metadata});

  factory NotificationJob.fromJson(Map<String, dynamic> json) {
    return NotificationJob(
      json['userId'] as String,
      json['message'] as String,
      title: json['title'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'userId': userId,
      'message': message,
    };

    if (title != null) data['title'] = title;
    if (metadata != null) data['metadata'] = metadata;

    return data;
  }

  @override
  Future<void> handle() async {
    executed = true;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  String get displayName => 'NotificationJob';
}

void main() {
  group('SerializableJob Mixin', () {
    test('should serialize job to JSON', () {
      final job = EmailJob(
        'test@example.com',
        'Welcome',
        'Hello World',
      );

      final json = job.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['email'], equals('test@example.com'));
      expect(json['subject'], equals('Welcome'));
      expect(json['body'], equals('Hello World'));
    });

    test('should deserialize job from JSON', () {
      final json = {
        'email': 'user@test.com',
        'subject': 'Test Subject',
        'body': 'Test Body',
      };

      final job = EmailJob.fromJson(json);

      expect(job.email, equals('user@test.com'));
      expect(job.subject, equals('Test Subject'));
      expect(job.body, equals('Test Body'));
    });

    test('should serialize and deserialize correctly (round-trip)', () {
      final original = EmailJob(
        'roundtrip@example.com',
        'Round Trip Test',
        'This should work!',
      );

      final json = original.toJson();
      final restored = EmailJob.fromJson(json);

      expect(restored.email, equals(original.email));
      expect(restored.subject, equals(original.subject));
      expect(restored.body, equals(original.body));
    });

    test('should execute job after deserialization', () async {
      final json = {
        'email': 'test@example.com',
        'subject': 'Test',
        'body': 'Message',
      };

      final job = EmailJob.fromJson(json);
      await job.handle();

      expect(job.executed, isTrue);
    });

    test('should have display name', () {
      final job = EmailJob('test@example.com', 'Subject', 'Body');

      expect(job.displayName, equals('EmailJob'));
    });
  });

  group('SerializableQueueJob Base Class', () {
    test('should serialize job to JSON', () {
      final job = PaymentJob('ORD-123', 99.99, currency: 'EUR');

      final json = job.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['orderId'], equals('ORD-123'));
      expect(json['amount'], equals(99.99));
      expect(json['currency'], equals('EUR'));
    });

    test('should deserialize job from JSON', () {
      final json = {
        'orderId': 'ORD-456',
        'amount': 149.99,
        'currency': 'GBP',
      };

      final job = PaymentJob.fromJson(json);

      expect(job.orderId, equals('ORD-456'));
      expect(job.amount, equals(149.99));
      expect(job.currency, equals('GBP'));
    });

    test('should use default values for optional parameters', () {
      final json = {
        'orderId': 'ORD-789',
        'amount': 25.00,
      };

      final job = PaymentJob.fromJson(json);

      expect(job.orderId, equals('ORD-789'));
      expect(job.amount, equals(25.00));
      expect(job.currency, equals('USD')); // Default value
    });

    test('should serialize and deserialize correctly (round-trip)', () {
      final original = PaymentJob('ORD-999', 199.99, currency: 'CAD');

      final json = original.toJson();
      final restored = PaymentJob.fromJson(json);

      expect(restored.orderId, equals(original.orderId));
      expect(restored.amount, equals(original.amount));
      expect(restored.currency, equals(original.currency));
    });

    test('should execute job after deserialization', () async {
      final json = {
        'orderId': 'ORD-111',
        'amount': 50.00,
        'currency': 'USD',
      };

      final job = PaymentJob.fromJson(json);
      await job.handle();

      expect(job.executed, isTrue);
    });

    test('should have display name', () {
      final job = PaymentJob('ORD-123', 99.99);

      expect(job.displayName, equals('PaymentJob'));
    });
  });

  group('Complex Data Types', () {
    test('should serialize Lists', () {
      final job = DataProcessingJob(
        ['item1', 'item2', 'item3'],
        {'key': 'value'},
        DateTime(2024, 1, 1, 12),
      );

      final json = job.toJson();

      expect(json['items'], isA<List>());
      expect(json['items'], hasLength(3));
      expect(json['items'][0], equals('item1'));
    });

    test('should deserialize Lists', () {
      final json = {
        'items': ['a', 'b', 'c'],
        'config': {'enabled': true},
        'scheduledAt': '2024-01-15T10:30:00.000',
      };

      final job = DataProcessingJob.fromJson(json);

      expect(job.items, isA<List<String>>());
      expect(job.items, hasLength(3));
      expect(job.items[1], equals('b'));
    });

    test('should serialize Maps', () {
      final job = DataProcessingJob(
        ['item'],
        {
          'threshold': 100,
          'enabled': true,
          'name': 'test',
        },
        DateTime(2024),
      );

      final json = job.toJson();

      expect(json['config'], isA<Map>());
      expect(json['config']['threshold'], equals(100));
      expect(json['config']['enabled'], isTrue);
    });

    test('should deserialize Maps', () {
      final json = {
        'items': ['test'],
        'config': {
          'retries': 3,
          'timeout': 30,
        },
        'scheduledAt': '2024-01-01T00:00:00.000',
      };

      final job = DataProcessingJob.fromJson(json);

      expect(job.config, isA<Map<String, dynamic>>());
      expect(job.config['retries'], equals(3));
      expect(job.config['timeout'], equals(30));
    });

    test('should serialize DateTime', () {
      final now = DateTime(2024, 6, 15, 14, 30, 45);
      final job = DataProcessingJob(['item'], {}, now);

      final json = job.toJson();

      expect(json['scheduledAt'], isA<String>());
      expect(json['scheduledAt'], equals('2024-06-15T14:30:45.000'));
    });

    test('should deserialize DateTime', () {
      final json = {
        'items': ['test'],
        'config': {},
        'scheduledAt': '2024-12-25T18:00:00.000',
      };

      final job = DataProcessingJob.fromJson(json);

      expect(job.scheduledAt, isA<DateTime>());
      expect(job.scheduledAt.year, equals(2024));
      expect(job.scheduledAt.month, equals(12));
      expect(job.scheduledAt.day, equals(25));
    });

    test('should serialize complex nested structures', () {
      final job = DataProcessingJob(
        ['item1', 'item2'],
        {
          'nested': {
            'deep': {
              'value': 42,
            },
          },
          'list': [1, 2, 3],
        },
        DateTime.now(),
      );

      final json = job.toJson();
      final restored = DataProcessingJob.fromJson(json);

      expect(restored.config['nested']['deep']['value'], equals(42));
      expect(restored.config['list'], equals([1, 2, 3]));
    });
  });

  group('Optional and Nullable Fields', () {
    test('should serialize with all fields', () {
      final job = NotificationJob(
        'user-123',
        'Hello User',
        title: 'Welcome',
        metadata: {'source': 'system'},
      );

      final json = job.toJson();

      expect(json['userId'], equals('user-123'));
      expect(json['message'], equals('Hello User'));
      expect(json['title'], equals('Welcome'));
      expect(json['metadata'], isNotNull);
      expect(json['metadata']['source'], equals('system'));
    });

    test('should serialize with only required fields', () {
      final job = NotificationJob('user-456', 'Simple message');

      final json = job.toJson();

      expect(json['userId'], equals('user-456'));
      expect(json['message'], equals('Simple message'));
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('should deserialize with all fields', () {
      final json = {
        'userId': 'user-789',
        'message': 'Test message',
        'title': 'Test Title',
        'metadata': {'type': 'info'},
      };

      final job = NotificationJob.fromJson(json);

      expect(job.userId, equals('user-789'));
      expect(job.message, equals('Test message'));
      expect(job.title, equals('Test Title'));
      expect(job.metadata, isNotNull);
      expect(job.metadata!['type'], equals('info'));
    });

    test('should deserialize with only required fields', () {
      final json = {
        'userId': 'user-000',
        'message': 'Minimal message',
      };

      final job = NotificationJob.fromJson(json);

      expect(job.userId, equals('user-000'));
      expect(job.message, equals('Minimal message'));
      expect(job.title, isNull);
      expect(job.metadata, isNull);
    });

    test('should handle null values in serialization round-trip', () {
      final original = NotificationJob(
        'user-111',
        'Message',
      );

      final json = original.toJson();
      final restored = NotificationJob.fromJson(json);

      expect(restored.userId, equals(original.userId));
      expect(restored.message, equals(original.message));
      expect(restored.title, isNull);
      expect(restored.metadata, isNull);
    });
  });

  group('Edge Cases', () {
    test('should handle empty strings', () {
      final job = EmailJob('', '', '');

      final json = job.toJson();
      final restored = EmailJob.fromJson(json);

      expect(restored.email, isEmpty);
      expect(restored.subject, isEmpty);
      expect(restored.body, isEmpty);
    });

    test('should handle empty collections', () {
      final job = DataProcessingJob([], {}, DateTime.now());

      final json = job.toJson();
      final restored = DataProcessingJob.fromJson(json);

      expect(restored.items, isEmpty);
      expect(restored.config, isEmpty);
    });

    test('should handle special characters in strings', () {
      final job = EmailJob(
        'test+alias@example.com',
        'Special: "Quotes" & \\Backslash\\',
        'Line1\nLine2\tTab',
      );

      final json = job.toJson();
      final restored = EmailJob.fromJson(json);

      expect(restored.email, equals(job.email));
      expect(restored.subject, equals(job.subject));
      expect(restored.body, equals(job.body));
    });

    test('should handle large numbers', () {
      final job = PaymentJob('ORD-999', 999999999.99);

      final json = job.toJson();
      final restored = PaymentJob.fromJson(json);

      expect(restored.amount, equals(999999999.99));
    });

    test('should handle zero and negative numbers', () {
      final job = PaymentJob('ORD-000', 0.00);

      final json = job.toJson();
      final restored = PaymentJob.fromJson(json);

      expect(restored.amount, equals(0.00));
    });

    test('should handle very long lists', () {
      final items = List.generate(1000, (i) => 'item-$i');
      final job = DataProcessingJob(items, {}, DateTime.now());

      final json = job.toJson();
      final restored = DataProcessingJob.fromJson(json);

      expect(restored.items.length, equals(1000));
      expect(restored.items.first, equals('item-0'));
      expect(restored.items.last, equals('item-999'));
    });
  });

  group('Job Execution After Serialization', () {
    test('should maintain job behavior after serialization', () async {
      final original = EmailJob(
        'test@example.com',
        'Subject',
        'Body',
      );

      // Serialize
      final json = original.toJson();

      // Deserialize
      final restored = EmailJob.fromJson(json);

      // Execute
      await restored.handle();

      expect(restored.executed, isTrue);
      expect(restored.displayName, equals('EmailJob'));
    });

    test('should execute different job types', () async {
      final emailJob = EmailJob('test@example.com', 'Sub', 'Body');
      final paymentJob = PaymentJob('ORD-123', 99.99);
      final notificationJob = NotificationJob('user-1', 'Hi');

      // Serialize all
      final emailJson = emailJob.toJson();
      final paymentJson = paymentJob.toJson();
      final notificationJson = notificationJob.toJson();

      // Deserialize all
      final restoredEmail = EmailJob.fromJson(emailJson);
      final restoredPayment = PaymentJob.fromJson(paymentJson);
      final restoredNotification = NotificationJob.fromJson(notificationJson);

      // Execute all
      await restoredEmail.handle();
      await restoredPayment.handle();
      await restoredNotification.handle();

      expect(restoredEmail.executed, isTrue);
      expect(restoredPayment.executed, isTrue);
      expect(restoredNotification.executed, isTrue);
    });
  });
}

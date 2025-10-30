import 'package:khadem/src/modules/mail/core/mail_message.dart';
import 'package:khadem/src/modules/mail/drivers/array_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ArrayTransport', () {
    late ArrayTransport transport;

    setUp(() {
      transport = ArrayTransport();
    });

    test('should have correct name', () {
      expect(transport.name, equals('array'));
    });

    test('should test successfully', () async {
      final result = await transport.test();
      expect(result, isTrue);
    });

    test('should start with no sent messages', () {
      expect(transport.count, equals(0));
      expect(transport.hasSent, isFalse);
      expect(transport.sent, isEmpty);
    });

    test('should store sent message', () async {
      final message = _createTestMessage();

      await transport.send(message);

      expect(transport.count, equals(1));
      expect(transport.hasSent, isTrue);
      expect(transport.sent.length, equals(1));
    });

    test('should store multiple messages', () async {
      final msg1 = _createTestMessage(to: 'user1@example.com');
      final msg2 = _createTestMessage(to: 'user2@example.com');
      final msg3 = _createTestMessage(to: 'user3@example.com');

      await transport.send(msg1);
      await transport.send(msg2);
      await transport.send(msg3);

      expect(transport.count, equals(3));
    });

    test('should return sent messages as unmodifiable list', () {
      final sent = transport.sent;

      expect(() => sent.add(_createTestMessage()), throwsUnsupportedError);
    });

    test('should clear sent messages', () async {
      await transport.send(_createTestMessage());
      await transport.send(_createTestMessage());

      expect(transport.count, equals(2));

      transport.clear();

      expect(transport.count, equals(0));
      expect(transport.hasSent, isFalse);
    });

    group('Query Methods', () {
      test('wasSent should find matching message', () async {
        final message = _createTestMessage(subject: 'Test Subject');
        await transport.send(message);

        final result =
            transport.wasSent((msg) => msg.subject == 'Test Subject');

        expect(result, isTrue);
      });

      test('wasSent should return false for non-matching', () async {
        final message = _createTestMessage(subject: 'Test Subject');
        await transport.send(message);

        final result = transport.wasSent((msg) => msg.subject == 'Other');

        expect(result, isFalse);
      });

      test('findSent should return matching messages', () async {
        await transport.send(_createTestMessage(to: 'user1@example.com'));
        await transport.send(_createTestMessage(to: 'user2@example.com'));
        await transport.send(_createTestMessage(to: 'user1@example.com'));

        final found = transport.findSent(
          (msg) => msg.to.any((addr) => addr.email == 'user1@example.com'),
        );

        expect(found.length, equals(2));
      });

      test('wasSentTo should find by recipient email', () async {
        await transport.send(_createTestMessage(to: 'user@example.com'));

        expect(transport.wasSentTo('user@example.com'), isTrue);
        expect(transport.wasSentTo('other@example.com'), isFalse);
      });

      test('wasSentWithSubject should find by subject', () async {
        await transport.send(_createTestMessage(subject: 'Welcome'));

        expect(transport.wasSentWithSubject('Welcome'), isTrue);
        expect(transport.wasSentWithSubject('Goodbye'), isFalse);
      });

      test('lastSent should return last message', () async {
        await transport.send(_createTestMessage(to: 'user1@example.com'));
        await transport.send(_createTestMessage(to: 'user2@example.com'));
        await transport.send(_createTestMessage(to: 'user3@example.com'));

        final last = transport.lastSent;

        expect(last, isNotNull);
        expect(last!.to.first.email, equals('user3@example.com'));
      });

      test('firstSent should return first message', () async {
        await transport.send(_createTestMessage(to: 'user1@example.com'));
        await transport.send(_createTestMessage(to: 'user2@example.com'));

        final first = transport.firstSent;

        expect(first, isNotNull);
        expect(first!.to.first.email, equals('user1@example.com'));
      });

      test('lastSent should return null when empty', () {
        expect(transport.lastSent, isNull);
      });

      test('firstSent should return null when empty', () {
        expect(transport.firstSent, isNull);
      });
    });

    group('Integration Scenarios', () {
      test('should handle complex queries', () async {
        // Send various emails
        await transport.send(
          _createTestMessage(
            to: 'admin@example.com',
            subject: 'Admin Alert',
          ),
        );
        await transport.send(
          _createTestMessage(
            to: 'user@example.com',
            subject: 'Welcome',
          ),
        );
        await transport.send(
          _createTestMessage(
            to: 'admin@example.com',
            subject: 'Another Alert',
          ),
        );

        // Find all admin emails
        final adminEmails = transport.findSent(
          (msg) => msg.to.any((addr) => addr.email == 'admin@example.com'),
        );

        expect(adminEmails.length, equals(2));

        // Find emails with "Alert" in subject
        final alerts = transport.findSent(
          (msg) => msg.subject?.contains('Alert') ?? false,
        );

        expect(alerts.length, equals(2));
      });

      test('should support test assertions pattern', () async {
        // Arrange
        const userEmail = 'newuser@example.com';

        // Act - simulate sending welcome email
        await transport.send(
          _createTestMessage(
            to: userEmail,
            subject: 'Welcome to our app!',
          ),
        );

        // Assert
        expect(transport.hasSent, isTrue);
        expect(transport.wasSentTo(userEmail), isTrue);
        expect(transport.wasSentWithSubject('Welcome to our app!'), isTrue);

        final sentMessage = transport.lastSent!;
        expect(sentMessage.to.first.email, equals(userEmail));
      });
    });
  });
}

/// Helper function to create test messages
MailMessage _createTestMessage({
  String? to,
  String? subject,
}) {
  final message = MailMessage();
  message.addTo(to ?? 'test@example.com');
  message.setSubject(subject ?? 'Test Email');
  message.setTextBody('Test content');
  return message;
}

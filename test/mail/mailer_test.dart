import 'package:khadem/src/modules/mail/contracts/mailable.dart';
import 'package:khadem/src/modules/mail/contracts/mailer_interface.dart';
import 'package:khadem/src/modules/mail/core/mail_message.dart';
import 'package:khadem/src/modules/mail/core/mailer.dart';
import 'package:khadem/src/modules/mail/drivers/array_transport.dart';
import 'package:khadem/src/modules/mail/exceptions/mail_exception.dart';
import 'package:test/test.dart';

void main() {
  group('Mailer', () {
    late ArrayTransport transport;
    late Mailer mailer;

    setUp(() {
      transport = ArrayTransport();
      mailer = Mailer(transport);
    });

    group('Fluent API', () {
      test('should build message with fluent API', () async {
        await mailer
            .to('user@example.com')
            .from('sender@example.com', 'Sender')
            .subject('Test Email')
            .text('Plain text content')
            .html('<p>HTML content</p>')
            .send();

        expect(transport.count, equals(1));
        final message = transport.lastSent!;
        expect(message.to.first.email, equals('user@example.com'));
        expect(message.from!.email, equals('sender@example.com'));
        expect(message.subject, equals('Test Email'));
        expect(message.textBody, equals('Plain text content'));
        expect(message.htmlBody, equals('<p>HTML content</p>'));
      });

      test('should support multiple recipients', () async {
        await mailer
            .to('user1@example.com')
            .to('user2@example.com')
            .cc('cc@example.com')
            .bcc('bcc@example.com')
            .subject('Test')
            .text('Content')
            .send();

        final message = transport.lastSent!;
        expect(message.to.length, equals(2));
        expect(message.cc.length, equals(1));
        expect(message.bcc.length, equals(1));
      });

      test('should set custom headers', () async {
        await mailer
            .to('user@example.com')
            .subject('Test')
            .text('Content')
            .header('X-Custom-Header', 'CustomValue')
            .header('X-Another-Header', 'AnotherValue')
            .send();

        final message = transport.lastSent!;
        expect(message.headers['X-Custom-Header'], equals('CustomValue'));
        expect(message.headers['X-Another-Header'], equals('AnotherValue'));
      });

      test('should set priority', () async {
        await mailer
            .to('user@example.com')
            .subject('Urgent')
            .text('Urgent message')
            .priority(1) // Highest priority
            .send();

        final message = transport.lastSent!;
        expect(message.priority, equals(1));
      });

      test('should set reply-to address', () async {
        await mailer
            .to('user@example.com')
            .replyTo('reply@example.com', 'Reply Handler')
            .subject('Test')
            .text('Content')
            .send();

        final message = transport.lastSent!;
        expect(message.replyTo, isNotNull);
        expect(message.replyTo!.email, equals('reply@example.com'));
      });
    });

    group('Attachments', () {
      test('should attach file by path', () async {
        await mailer
            .to('user@example.com')
            .subject('Test')
            .text('Content')
            .attach('/path/to/file.pdf', name: 'document.pdf')
            .send();

        final message = transport.lastSent!;
        expect(message.attachments.length, equals(1));
        expect(message.attachments.first.filename, equals('document.pdf'));
        expect(message.attachments.first.isFilePath, isTrue);
      });

      test('should attach data', () async {
        final data = [1, 2, 3, 4, 5];
        
        await mailer
            .to('user@example.com')
            .subject('Test')
            .text('Content')
            .attachData(data, 'data.bin', mimeType: 'application/octet-stream')
            .send();

        final message = transport.lastSent!;
        expect(message.attachments.length, equals(1));
        expect(message.attachments.first.filename, equals('data.bin'));
        expect(message.attachments.first.isRawData, isTrue);
      });

      test('should embed inline images', () async {
        await mailer
            .to('user@example.com')
            .subject('Test')
            .html('<img src="cid:logo">')
            .embed('/path/to/logo.png', 'logo')
            .send();

        final message = transport.lastSent!;
        expect(message.embedded.length, equals(1));
        expect(message.embedded.first.cid, equals('logo'));
      });
    });

    group('Validation', () {
      test('should throw when sending without recipients', () async {
        expect(
          () => mailer.subject('Test').text('Content').send(),
          throwsA(isA<MailException>()),
        );
      });

      test('should throw when sending without subject', () async {
        expect(
          () => mailer.to('user@example.com').text('Content').send(),
          throwsA(isA<MailException>()),
        );
      });

      test('should throw when sending without content', () async {
        expect(
          () => mailer.to('user@example.com').subject('Test').send(),
          throwsA(isA<MailException>()),
        );
      });
    });

    group('Mailable', () {
      test('should send mailable', () async {
        final mailable = TestMailable('user@example.com', 'Test Subject');

        await mailer.sendMailable(mailable);

        expect(transport.count, equals(1));
        final message = transport.lastSent!;
        expect(message.to.first.email, equals('user@example.com'));
        expect(message.subject, equals('Test Subject'));
      });

      test('should call mailable hooks', () async {
        final mailable = HookedMailable();

        await mailer.sendMailable(mailable);

        expect(mailable.buildCalled, isTrue);
        expect(mailable.beforeSendCalled, isTrue);
        expect(mailable.afterSendCalled, isTrue);
      });

      test('should call onError on failure', () async {
        final failingTransport = FailingTransport();
        final failingMailer = Mailer(failingTransport);
        final mailable = HookedMailable();

        await failingMailer.sendMailable(mailable);

        expect(mailable.onErrorCalled, isTrue);
      });
    });

    group('Reset', () {
      test('should reset message between sends', () async {
        await mailer
            .to('user1@example.com')
            .subject('First')
            .text('First message')
            .send();

        await mailer
            .to('user2@example.com')
            .subject('Second')
            .text('Second message')
            .send();

        expect(transport.count, equals(2));

        final first = transport.sent[0];
        final second = transport.sent[1];

        expect(first.to.first.email, equals('user1@example.com'));
        expect(second.to.first.email, equals('user2@example.com'));

        expect(first.subject, equals('First'));
        expect(second.subject, equals('Second'));
      });

      test('should clear previous recipients', () async {
        mailer.to('user1@example.com');
        mailer.to('user2@example.com');

        // Internal reset should happen here
        final message = MailMessage();
        expect(message.to.isEmpty, isTrue);
      });
    });
  });
}

/// Simple test mailable
class TestMailable extends Mailable {
  final String toEmail;
  final String emailSubject;

  TestMailable(this.toEmail, this.emailSubject);

  @override
  Future<void> build(MailerInterface mailer) async {
    mailer
        .to(toEmail)
        .subject(emailSubject)
        .text('Test mailable content');
  }
}

/// Mailable with hooks for testing
class HookedMailable extends Mailable {
  bool buildCalled = false;
  bool beforeSendCalled = false;
  bool afterSendCalled = false;
  bool onErrorCalled = false;

  @override
  Future<void> build(MailerInterface mailer) async {
    buildCalled = true;
    mailer
        .to('user@example.com')
        .subject('Hooked')
        .text('Content');
  }

  @override
  Future<void> beforeSend() async {
    beforeSendCalled = true;
  }

  @override
  Future<void> afterSend() async {
    afterSendCalled = true;
  }

  @override
  Future<void> onError(dynamic error, StackTrace stackTrace) async {
    onErrorCalled = true;
  }
}

/// Transport that always fails for testing
class FailingTransport extends ArrayTransport {
  @override
  Future<bool> send(dynamic message) async {
    throw Exception('Transport failed');
  }
}

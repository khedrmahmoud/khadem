import 'package:khadem/src/modules/mail/contracts/mail_message_interface.dart';
import 'package:khadem/src/modules/mail/core/mail_message.dart';
import 'package:khadem/src/modules/mail/exceptions/mail_exception.dart';
import 'package:test/test.dart';

void main() {
  group('MailMessage', () {
    late MailMessage message;

    setUp(() {
      message = MailMessage();
    });

    group('Recipients', () {
      test('should add to recipient', () {
        message.addTo('user@example.com', 'John Doe');

        expect(message.to.length, equals(1));
        expect(message.to.first.email, equals('user@example.com'));
        expect(message.to.first.name, equals('John Doe'));
      });

      test('should add multiple to recipients', () {
        message.addTo('user1@example.com');
        message.addTo('user2@example.com', 'User Two');

        expect(message.to.length, equals(2));
        expect(message.to[0].email, equals('user1@example.com'));
        expect(message.to[1].name, equals('User Two'));
      });

      test('should add CC recipient', () {
        message.addCc('cc@example.com', 'CC User');

        expect(message.cc.length, equals(1));
        expect(message.cc.first.email, equals('cc@example.com'));
      });

      test('should add BCC recipient', () {
        message.addBcc('bcc@example.com');

        expect(message.bcc.length, equals(1));
        expect(message.bcc.first.email, equals('bcc@example.com'));
      });
    });

    group('Sender and Reply-To', () {
      test('should set from address', () {
        message.setFrom('from@example.com', 'Sender');

        expect(message.from, isNotNull);
        expect(message.from!.email, equals('from@example.com'));
        expect(message.from!.name, equals('Sender'));
      });

      test('should set reply-to address', () {
        message.setReplyTo('reply@example.com', 'Reply User');

        expect(message.replyTo, isNotNull);
        expect(message.replyTo!.email, equals('reply@example.com'));
      });
    });

    group('Content', () {
      test('should set subject', () {
        message.setSubject('Test Subject');

        expect(message.subject, equals('Test Subject'));
      });

      test('should set text body', () {
        message.setTextBody('Plain text content');

        expect(message.textBody, equals('Plain text content'));
      });

      test('should set HTML body', () {
        message.setHtmlBody('<h1>HTML Content</h1>');

        expect(message.htmlBody, equals('<h1>HTML Content</h1>'));
      });
    });

    group('Attachments', () {
      test('should add file attachment', () {
        const attachment = MailAttachment(
          path: '/path/to/file.pdf',
          filename: 'document.pdf',
          mimeType: 'application/pdf',
        );

        message.addAttachment(attachment);

        expect(message.attachments.length, equals(1));
        expect(message.attachments.first.filename, equals('document.pdf'));
        expect(message.attachments.first.isFilePath, isTrue);
      });

      test('should add data attachment', () {
        const attachment = MailAttachment(
          data: [1, 2, 3, 4],
          filename: 'data.bin',
          mimeType: 'application/octet-stream',
        );

        message.addAttachment(attachment);

        expect(message.attachments.length, equals(1));
        expect(message.attachments.first.isRawData, isTrue);
      });

      test('should add embedded file', () {
        const embedded = MailEmbedded(
          path: '/path/to/logo.png',
          cid: 'logo',
          mimeType: 'image/png',
        );

        message.addEmbedded(embedded);

        expect(message.embedded.length, equals(1));
        expect(message.embedded.first.cid, equals('logo'));
      });
    });

    group('Headers and Priority', () {
      test('should set custom header', () {
        message.setHeader('X-Custom-Header', 'value');

        expect(message.headers['X-Custom-Header'], equals('value'));
      });

      test('should set priority', () {
        message.setPriority(1); // Highest

        expect(message.priority, equals(1));
      });

      test('should throw on invalid priority', () {
        expect(() => message.setPriority(0), throwsA(isA<MailException>()));
        expect(() => message.setPriority(6), throwsA(isA<MailException>()));
      });

      test('should default to normal priority', () {
        expect(message.priority, equals(3));
      });
    });

    group('Validation', () {
      test('should throw when no recipients', () {
        message.setSubject('Test');
        message.setTextBody('Content');

        expect(() => message.validate(), throwsA(isA<MailException>()));
      });

      test('should throw when no subject', () {
        message.addTo('user@example.com');
        message.setTextBody('Content');

        expect(() => message.validate(), throwsA(isA<MailException>()));
      });

      test('should throw when subject is empty', () {
        message.addTo('user@example.com');
        message.setSubject('   ');
        message.setTextBody('Content');

        expect(() => message.validate(), throwsA(isA<MailException>()));
      });

      test('should throw when no content', () {
        message.addTo('user@example.com');
        message.setSubject('Test');

        expect(() => message.validate(), throwsA(isA<MailException>()));
      });

      test('should throw when content is empty', () {
        message.addTo('user@example.com');
        message.setSubject('Test');
        message.setTextBody('   ');

        expect(() => message.validate(), throwsA(isA<MailException>()));
      });

      test('should validate with text body only', () {
        message.addTo('user@example.com');
        message.setSubject('Test');
        message.setTextBody('Valid content');

        expect(() => message.validate(), returnsNormally);
      });

      test('should validate with HTML body only', () {
        message.addTo('user@example.com');
        message.setSubject('Test');
        message.setHtmlBody('<p>Valid content</p>');

        expect(() => message.validate(), returnsNormally);
      });

      test('should validate with CC recipient only', () {
        message.addCc('user@example.com');
        message.setSubject('Test');
        message.setTextBody('Content');

        expect(() => message.validate(), returnsNormally);
      });

      test('should validate with BCC recipient only', () {
        message.addBcc('user@example.com');
        message.setSubject('Test');
        message.setTextBody('Content');

        expect(() => message.validate(), returnsNormally);
      });

      test('should throw on invalid email address', () {
        message.addTo('invalid-email');
        message.setSubject('Test');
        message.setTextBody('Content');

        expect(() => message.validate(), throwsA(isA<MailException>()));
      });

      test('should throw on invalid from address', () {
        message.addTo('user@example.com');
        message.setFrom('invalid-from');
        message.setSubject('Test');
        message.setTextBody('Content');

        expect(() => message.validate(), throwsA(isA<MailException>()));
      });

      test('should validate correct email addresses', () {
        message.addTo('user@example.com');
        message.addCc('cc.user@example.co.uk');
        message.addBcc('bcc_user@sub.example.com');
        message.setFrom('sender@example.com');
        message.setSubject('Test');
        message.setTextBody('Content');

        expect(() => message.validate(), returnsNormally);
      });
    });

    group('Copy', () {
      test('should create a copy of the message', () {
        message.addTo('user@example.com', 'User');
        message.setFrom('from@example.com');
        message.setSubject('Test');
        message.setTextBody('Text');
        message.setHtmlBody('<p>HTML</p>');
        message.setPriority(1);
        message.setHeader('X-Custom', 'value');

        final copy = message.copy();

        expect(copy.to.length, equals(1));
        expect(copy.to.first.email, equals('user@example.com'));
        expect(copy.from!.email, equals('from@example.com'));
        expect(copy.subject, equals('Test'));
        expect(copy.textBody, equals('Text'));
        expect(copy.htmlBody, equals('<p>HTML</p>'));
        expect(copy.priority, equals(1));
        expect(copy.headers['X-Custom'], equals('value'));
      });

      test('should create independent copy', () {
        message.addTo('user@example.com');
        final copy = message.copy();

        message.addTo('another@example.com');

        expect(message.to.length, equals(2));
        expect(copy.to.length, equals(1));
      });
    });
  });

  group('MailAddress', () {
    test('should create address with email only', () {
      const address = MailAddress('user@example.com');

      expect(address.email, equals('user@example.com'));
      expect(address.name, isNull);
    });

    test('should create address with name', () {
      const address = MailAddress('user@example.com', 'John Doe');

      expect(address.email, equals('user@example.com'));
      expect(address.name, equals('John Doe'));
    });

    test('should format toString without name', () {
      const address = MailAddress('user@example.com');

      expect(address.toString(), equals('user@example.com'));
    });

    test('should format toString with name', () {
      const address = MailAddress('user@example.com', 'John Doe');

      expect(address.toString(), equals('John Doe <user@example.com>'));
    });

    test('should compare addresses correctly', () {
      const addr1 = MailAddress('user@example.com', 'John');
      const addr2 = MailAddress('user@example.com', 'John');
      const addr3 = MailAddress('user@example.com', 'Jane');
      const addr4 = MailAddress('other@example.com', 'John');

      expect(addr1, equals(addr2));
      expect(addr1, isNot(equals(addr3)));
      expect(addr1, isNot(equals(addr4)));
    });
  });

  group('MailAttachment', () {
    test('should create file attachment', () {
      const attachment = MailAttachment(
        path: '/path/to/file.pdf',
        filename: 'document.pdf',
      );

      expect(attachment.isFilePath, isTrue);
      expect(attachment.isRawData, isFalse);
    });

    test('should create data attachment', () {
      const attachment = MailAttachment(
        data: [1, 2, 3],
        filename: 'data.bin',
      );

      expect(attachment.isFilePath, isFalse);
      expect(attachment.isRawData, isTrue);
    });
  });
}

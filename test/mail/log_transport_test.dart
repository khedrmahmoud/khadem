import 'package:khadem/src/core/logging/logger.dart';
import 'package:khadem/src/modules/mail/contracts/mail_message_interface.dart';
import 'package:khadem/src/modules/mail/core/mail_message.dart';
import 'package:khadem/src/modules/mail/drivers/log_transport.dart';
import 'package:test/test.dart';

void main() {
  group('LogTransport', () {
    late LogTransport transport;
    late TestLogger logger;

    setUp(() {
      logger = TestLogger();
      transport = LogTransport(logger);
    });

    test('should have correct name', () {
      expect(transport.name, equals('log'));
    });

    test('should test successfully', () async {
      final result = await transport.test();
      expect(result, isTrue);
      expect(logger.infoMessages.isNotEmpty, isTrue);
    });

    test('should log basic email info', () async {
      final message = MailMessage();
      message.addTo('user@example.com', 'Test User');
      message.setFrom('from@example.com', 'Sender');
      message.setSubject('Test Subject');
      message.setTextBody('Test content');

      final result = await transport.send(message);

      expect(result, isTrue);
      expect(logger.infoMessages.any((m) => m.contains('Email logged')), isTrue);
      expect(logger.infoMessages.any((m) => m.contains('user@example.com')), isTrue);
      expect(logger.infoMessages.any((m) => m.contains('Test Subject')), isTrue);
    });

    test('should log CC recipients when present', () async {
      final message = MailMessage();
      message.addTo('to@example.com');
      message.addCc('cc@example.com');
      message.setSubject('Test');
      message.setTextBody('Content');

      await transport.send(message);

      expect(logger.infoMessages.any((m) => m.contains('CC:')), isTrue);
      expect(logger.infoMessages.any((m) => m.contains('cc@example.com')), isTrue);
    });

    test('should log BCC recipients when present', () async {
      final message = MailMessage();
      message.addTo('to@example.com');
      message.addBcc('bcc@example.com');
      message.setSubject('Test');
      message.setTextBody('Content');

      await transport.send(message);

      expect(logger.infoMessages.any((m) => m.contains('BCC:')), isTrue);
      expect(logger.infoMessages.any((m) => m.contains('bcc@example.com')), isTrue);
    });

    test('should log verbose details when enabled', () async {
      final verboseTransport = LogTransport(logger, verbose: true);
      
      final message = MailMessage();
      message.addTo('user@example.com');
      message.setSubject('Test');
      message.setTextBody('Plain text content');
      message.setHtmlBody('<h1>HTML Content</h1>');

      await verboseTransport.send(message);

      expect(logger.infoMessages.any((m) => m.contains('Text Body:')), isTrue);
      expect(logger.infoMessages.any((m) => m.contains('HTML Body:')), isTrue);
    });

    test('should not log verbose details when disabled', () async {
      final nonVerboseTransport = LogTransport(logger, verbose: false);
      
      final message = MailMessage();
      message.addTo('user@example.com');
      message.setSubject('Test');
      message.setTextBody('Plain text content');

      await nonVerboseTransport.send(message);

      expect(logger.infoMessages.any((m) => m.contains('Text Body:')), isFalse);
    });

    test('should log attachments count when verbose', () async {
      final verboseTransport = LogTransport(logger, verbose: true);
      
      final message = MailMessage();
      message.addTo('user@example.com');
      message.setSubject('Test');
      message.setTextBody('Content');
      message.addAttachment(MailAttachment(
        data: [1, 2, 3],
        filename: 'file1.pdf',
      ));
      message.addAttachment(MailAttachment(
        data: [4, 5, 6],
        filename: 'file2.pdf',
      ));

      await verboseTransport.send(message);

      expect(logger.infoMessages.any((m) => m.contains('Attachments: 2')), isTrue);
      expect(logger.infoMessages.any((m) => m.contains('file1.pdf')), isTrue);
      expect(logger.infoMessages.any((m) => m.contains('file2.pdf')), isTrue);
    });

    test('should log embedded files when verbose', () async {
      final verboseTransport = LogTransport(logger, verbose: true);
      
      final message = MailMessage();
      message.addTo('user@example.com');
      message.setSubject('Test');
      message.setTextBody('Content');
      message.addEmbedded(MailEmbedded(
        path: '/path/to/logo.png',
        cid: 'logo',
      ));

      await verboseTransport.send(message);

      expect(logger.infoMessages.any((m) => m.contains('Embedded:')), isTrue);
      expect(logger.infoMessages.any((m) => m.contains('logo')), isTrue);
    });

    test('should handle errors gracefully', () async {
      final failingLogger = FailingLogger();
      final failingTransport = LogTransport(failingLogger);

      final message = MailMessage();
      message.addTo('user@example.com');
      message.setSubject('Test');
      message.setTextBody('Content');

      final result = await failingTransport.send(message);

      expect(result, isFalse);
      expect(failingLogger.errorMessages.isNotEmpty, isTrue);
    });
  });
}

/// Test logger that captures log messages for testing
class TestLogger extends Logger {
  final List<String> infoMessages = [];
  final List<String> errorMessages = [];

  @override
  void info(String message, {String? channel, Map<String, dynamic>? context, StackTrace? stackTrace}) {
    infoMessages.add(message);
  }

  @override
  void error(String message, {String? channel, Map<String, dynamic>? context, StackTrace? stackTrace}) {
    errorMessages.add(message);
  }
}

/// Logger that fails on info calls to test error handling
class FailingLogger extends Logger {
  final List<String> errorMessages = [];

  @override
  void info(String message, {String? channel, Map<String, dynamic>? context, StackTrace? stackTrace}) {
    if (message.contains('Email logged')) {
      throw Exception('Logger failure');
    }
  }

  @override
  void error(String message, {String? channel, Map<String, dynamic>? context, StackTrace? stackTrace}) {
    errorMessages.add(message);
  }
}

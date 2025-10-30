import 'package:khadem/src/contracts/config/config_contract.dart';
import 'package:khadem/src/core/logging/logger.dart';
import 'package:khadem/src/modules/mail/contracts/mailable.dart';
import 'package:khadem/src/modules/mail/contracts/mailer_interface.dart';
import 'package:khadem/src/modules/mail/core/mail_manager.dart';
import 'package:khadem/src/modules/mail/drivers/array_transport.dart';
import 'package:khadem/src/modules/mail/drivers/log_transport.dart';
import 'package:khadem/src/modules/mail/exceptions/mail_exception.dart';
import 'package:test/test.dart';

void main() {
  group('MailManager', () {
    late MailManager mailManager;
    late MockConfig mockConfig;

    setUp(() {
      mockConfig = MockConfig();
      mailManager = MailManager(mockConfig);
    });

    group('Transport Registration', () {
      test('should register transport', () {
        final transport = ArrayTransport();

        mailManager.registerTransport('array', transport);

        expect(() => mailManager.mailer('array'), returnsNormally);
      });

      test('should throw when accessing unregistered transport', () {
        expect(
          () => mailManager.mailer('nonexistent'),
          throwsA(isA<MailConfigException>()),
        );
      });

      test('should return same mailer instance for transport', () {
        final transport = ArrayTransport();
        mailManager.registerTransport('array', transport);

        final mailer1 = mailManager.mailer('array');
        final mailer2 = mailManager.mailer('array');

        expect(identical(mailer1, mailer2), isTrue);
      });
    });

    group('Default Transport', () {
      test('should use default transport from config', () {
        mockConfig.defaultTransport = 'array';
        final manager = MailManager(mockConfig);

        final transport = ArrayTransport();
        manager.registerTransport('array', transport);

        final defaultMailer = manager.defaultMailer;
        expect(defaultMailer, isNotNull);
      });

      test('should throw when default transport not registered', () {
        mockConfig.defaultTransport = 'smtp';
        final manager = MailManager(mockConfig);

        expect(
          () => manager.defaultMailer,
          throwsA(isA<MailConfigException>()),
        );
      });
    });

    group('Fluent API Proxy', () {
      test('should proxy to(), from(), subject() to default mailer', () async {
        mockConfig.defaultTransport = 'array';
        final transport = ArrayTransport();
        final manager = MailManager(mockConfig);
        manager.registerTransport('array', transport);

        await manager
            .to('user@example.com')
            .from('sender@example.com')
            .subject('Test')
            .text('Content')
            .send();

        expect(transport.count, equals(1));
        final message = transport.lastSent!;
        expect(message.to.first.email, equals('user@example.com'));
        expect(message.subject, equals('Test'));
      });

      test('should proxy attachment methods', () async {
        mockConfig.defaultTransport = 'array';
        final transport = ArrayTransport();
        final manager = MailManager(mockConfig);
        manager.registerTransport('array', transport);

        await manager
            .to('user@example.com')
            .subject('Test')
            .text('Content')
            .attach('/path/to/file.pdf')
            .send();

        final message = transport.lastSent!;
        expect(message.attachments.length, equals(1));
      });

      test('should proxy sendMailable', () async {
        mockConfig.defaultTransport = 'array';
        final transport = ArrayTransport();
        final manager = MailManager(mockConfig);
        manager.registerTransport('array', transport);

        final mailable = TestMailable();
        await manager.sendMailable(mailable);

        expect(transport.count, equals(1));
      });
    });

    group('Transport Testing', () {
      test('should test specific transport', () async {
        final transport = ArrayTransport();
        mailManager.registerTransport('array', transport);

        final result = await transport.test();
        expect(result, isTrue);
      });
    });

    group('Multiple Transports', () {
      test('should support multiple transports', () {
        final arrayTransport = ArrayTransport();
        final logTransport = LogTransport(TestLogger());

        mailManager.registerTransport('array', arrayTransport);
        mailManager.registerTransport('log', logTransport);

        final arrayMailer = mailManager.mailer('array');
        final logMailer = mailManager.mailer('log');

        expect(arrayMailer, isNotNull);
        expect(logMailer, isNotNull);
        expect(identical(arrayMailer, logMailer), isFalse);
      });

      test('should send through different transports', () async {
        final transport1 = ArrayTransport();
        final transport2 = ArrayTransport();

        mailManager.registerTransport('transport1', transport1);
        mailManager.registerTransport('transport2', transport2);

        await mailManager
            .mailer('transport1')
            .to('user1@example.com')
            .subject('Transport 1')
            .text('Content')
            .send();

        await mailManager
            .mailer('transport2')
            .to('user2@example.com')
            .subject('Transport 2')
            .text('Content')
            .send();

        expect(transport1.count, equals(1));
        expect(transport2.count, equals(1));

        expect(transport1.lastSent!.subject, equals('Transport 1'));
        expect(transport2.lastSent!.subject, equals('Transport 2'));
      });
    });

    group('Transport Names', () {
      test('should handle registered transports', () {
        mailManager.registerTransport('array', ArrayTransport());
        mailManager.registerTransport('log', LogTransport(TestLogger()));

        // Just verify we can get the mailers
        expect(() => mailManager.mailer('array'), returnsNormally);
        expect(() => mailManager.mailer('log'), returnsNormally);
      });
    });
  });
}

/// Mock config for testing
class MockConfig implements ConfigInterface {
  String defaultTransport = 'array';
  String fromEmail = 'from@example.com';
  String? fromName = 'Sender';

  @override
  T? get<T>(String key, [T? defaultValue]) {
    if (key == 'mail.default') {
      return defaultTransport as T?;
    }
    if (key == 'mail.from.address') {
      return fromEmail as T?;
    }
    if (key == 'mail.from.name') {
      return fromName as T?;
    }
    return defaultValue;
  }

  @override
  bool has(String key) => true;

  @override
  void set(String key, dynamic value) {}

  @override
  Map<String, dynamic> all() => {};

  @override
  Future<void> reload() async {}

  @override
  void loadFromRegistry(Map<String, Map<String, dynamic>> registry) {}

  @override
  Map<String, dynamic> section(String section) => {};
}

/// Simple test logger that extends Logger
class TestLogger extends Logger {
  @override
  void info(
    String message, {
    String? channel,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    // Capture message if needed
  }

  @override
  void error(
    String message, {
    String? channel,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    // Capture error if needed
  }
}

/// Simple test mailable
class TestMailable extends Mailable {
  @override
  Future<void> build(MailerInterface mailer) async {
    mailer.to('test@example.com').subject('Test').text('Content');
  }
}

import '../../../contracts/container/container_interface.dart';
import '../../../contracts/provider/service_provider.dart';
import '../../../core/queue/queue_manager.dart';
import '../config/mail_config.dart';
import '../drivers/array_transport.dart';
import '../drivers/log_transport.dart';
import '../drivers/smtp_transport.dart';
import 'mail_manager.dart';

/// Service provider for the mail module.
///
/// Registers mail services in the container.
class MailServiceProvider implements ServiceProvider {
  @override
  bool get isDeferred => false;

  @override
  void register(ContainerInterface container) {
    // Register MailManager as singleton
    container.singleton<MailManager>((c) {
      final config = c.resolve();
      final queueManager = c.has<QueueManager>() 
          ? c.resolve<QueueManager>() 
          : null;

      final mailManager = MailManager(config, queueManager: queueManager);

      // Register default transports
      _registerDefaultTransports(mailManager, c);

      return mailManager;
    });
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    // Nothing to boot for now
  }

  /// Registers default mail transports.
  void _registerDefaultTransports(
    MailManager mailManager,
    ContainerInterface container,
  ) {
    final config = container.resolve();
    final logger = container.resolve();

    // Register log transport (for development)
    mailManager.registerTransport('log', LogTransport(logger));

    // Register array transport (for testing)
    mailManager.registerTransport('array', ArrayTransport());

    // Register SMTP transport if configured
    final smtpConfig = config.get<Map<String, dynamic>>('mail.smtp');
    if (smtpConfig != null) {
      final smtp = SmtpConfig.fromMap(smtpConfig);
      mailManager.registerTransport('smtp', SmtpTransport(smtp));
    }

    // Register Mailgun transport if configured
    final mailgunConfig = config.get<Map<String, dynamic>>('mail.mailgun');
    if (mailgunConfig != null) {
      // TODO: Implement MailgunTransport when needed
      // final mailgun = MailgunConfig.fromMap(mailgunConfig);
      // mailManager.registerTransport('mailgun', MailgunTransport(mailgun));
    }

    // Register SES transport if configured
    final sesConfig = config.get<Map<String, dynamic>>('mail.ses');
    if (sesConfig != null) {
      // TODO: Implement SesTransport when needed
      // final ses = SesConfig.fromMap(sesConfig);
      // mailManager.registerTransport('ses', SesTransport(ses));
    }

    // Register Postmark transport if configured
    final postmarkConfig = config.get<Map<String, dynamic>>('mail.postmark');
    if (postmarkConfig != null) {
      // TODO: Implement PostmarkTransport when needed
      // final postmark = PostmarkConfig.fromMap(postmarkConfig);
      // mailManager.registerTransport('postmark', PostmarkTransport(postmark));
    }
  }
}

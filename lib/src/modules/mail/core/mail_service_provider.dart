import '../../../contracts/container/container_interface.dart';
import '../../../contracts/provider/service_provider.dart';
import '../../../core/queue/queue_manager.dart';
import '../drivers/array_transport.dart';
import '../drivers/log_transport.dart';
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
    // Register log transport (for development)
    final logger = container.resolve();
    mailManager.registerTransport('log', LogTransport(logger));

    // Register array transport (for testing)
    mailManager.registerTransport('array', ArrayTransport());

    // Future: SMTP, SES, Mailgun, etc. will be registered here
  }
}

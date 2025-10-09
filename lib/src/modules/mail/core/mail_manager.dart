import '../../../contracts/config/config_contract.dart';
import '../../../core/queue/queue_manager.dart';
import '../contracts/mailable.dart';
import '../contracts/mail_message_interface.dart';
import '../contracts/mailer_interface.dart';
import '../contracts/transport_interface.dart';
import '../exceptions/mail_exception.dart';
import 'mailer.dart';

/// Manages multiple mail drivers/transports.
///
/// Allows switching between different mail services (SMTP, SES, Mailgun, etc.)
/// and provides a convenient API for sending emails.
///
/// Example:
/// ```dart
/// final mailManager = MailManager(config, queueManager);
/// 
/// // Use default mailer
/// await mailManager.to('user@example.com')
///     .subject('Hello')
///     .text('Hello World')
///     .send();
/// 
/// // Use specific mailer
/// await mailManager.mailer('ses')
///     .to('user@example.com')
///     .subject('Hello')
///     .send();
/// ```
class MailManager implements MailerInterface {
  final ConfigInterface _config;
  final QueueManager? _queueManager;
  final Map<String, TransportInterface> _transports = {};
  final Map<String, MailerInterface> _mailers = {};

  String? _defaultMailer;
  MailAddress? _defaultFrom;

  MailManager(this._config, {QueueManager? queueManager})
      : _queueManager = queueManager {
    _loadConfiguration();
  }

  /// Loads mail configuration.
  void _loadConfiguration() {
    // Load default mailer
    _defaultMailer = _config.get<String>('mail.default', 'smtp');

    // Load default from address
    final fromConfig = _config.get<Map<String, dynamic>>('mail.from');
    if (fromConfig != null) {
      final email = fromConfig['address'] as String?;
      final name = fromConfig['name'] as String?;
      if (email != null) {
        _defaultFrom = MailAddress(email, name);
      }
    }
  }

  /// Registers a mail transport driver.
  void registerTransport(String name, TransportInterface transport) {
    _transports[name] = transport;
  }

  /// Gets a mailer instance by name.
  ///
  /// If not specified, returns the default mailer.
  MailerInterface mailer([String? name]) {
    final mailerName = name ?? _defaultMailer ?? 'smtp';

    // Return cached mailer if available
    if (_mailers.containsKey(mailerName)) {
      return _mailers[mailerName]!;
    }

    // Get or create transport
    final transport = _transports[mailerName];
    if (transport == null) {
      throw MailConfigException('Mail transport "$mailerName" not registered');
    }

    // Create new mailer
    final mailer = Mailer(
      transport,
      queueManager: _queueManager,
      defaultFrom: _defaultFrom,
    );

    _mailers[mailerName] = mailer;
    return mailer;
  }

  /// Gets the default mailer.
  MailerInterface get defaultMailer => mailer();

  // Proxy methods to default mailer for convenience

  @override
  MailerInterface to(dynamic addresses) => defaultMailer.to(addresses);

  @override
  MailerInterface cc(dynamic addresses) => defaultMailer.cc(addresses);

  @override
  MailerInterface bcc(dynamic addresses) => defaultMailer.bcc(addresses);

  @override
  MailerInterface replyTo(String address, [String? name]) =>
      defaultMailer.replyTo(address, name);

  @override
  MailerInterface subject(String subject) => defaultMailer.subject(subject);

  @override
  MailerInterface from(String address, [String? name]) =>
      defaultMailer.from(address, name);

  @override
  MailerInterface text(String content) => defaultMailer.text(content);

  @override
  MailerInterface html(String content) => defaultMailer.html(content);

  @override
  Future<MailerInterface> view(String viewName,
          [Map<String, dynamic>? data]) =>
      defaultMailer.view(viewName, data);

  @override
  MailerInterface attach(String path, {String? name, String? mimeType}) =>
      defaultMailer.attach(path, name: name, mimeType: mimeType);

  @override
  MailerInterface attachData(List<int> data, String name,
          {String? mimeType}) =>
      defaultMailer.attachData(data, name, mimeType: mimeType);

  @override
  MailerInterface embed(String path, String cid) =>
      defaultMailer.embed(path, cid);

  @override
  MailerInterface header(String name, String value) =>
      defaultMailer.header(name, value);

  @override
  MailerInterface priority(int priority) => defaultMailer.priority(priority);

  @override
  Future<bool> send() => defaultMailer.send();

  @override
  Future<void> queue([Duration? delay]) => defaultMailer.queue(delay);

  @override
  Future<bool> sendMailable(Mailable mailable) =>
      defaultMailer.sendMailable(mailable);

  @override
  Future<void> queueMailable(Mailable mailable, [Duration? delay]) =>
      defaultMailer.queueMailable(mailable, delay);

  @override
  MailMessageInterface message() => defaultMailer.message();

  @override
  String get driverName => defaultMailer.driverName;

  /// Tests a mail transport connection.
  Future<bool> testTransport([String? name]) async {
    final mailerName = name ?? _defaultMailer ?? 'smtp';
    final transport = _transports[mailerName];
    
    if (transport == null) {
      throw MailConfigException('Mail transport "$mailerName" not registered');
    }

    return transport.test();
  }

  /// Gets list of registered transport names.
  List<String> get availableTransports => _transports.keys.toList();

  /// Clears all cached mailers (useful for testing).
  void clearMailers() {
    _mailers.clear();
  }
}

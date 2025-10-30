import '../../application/khadem.dart';
import 'contracts/mailable.dart';
import 'contracts/mailer_interface.dart';
import 'core/mail_manager.dart';

/// Mail facade for convenient access to mail functionality.
///
/// Provides static methods for sending emails.
///
/// Example:
/// ```dart
/// // Send simple email
/// await Mail.to('user@example.com')
///     .subject('Welcome!')
///     .text('Welcome to our app')
///     .send();
///
/// // Send with view
/// await Mail.to('user@example.com')
///     .subject('Welcome!')
///     .view('emails.welcome', {'name': 'John'})
///     .send();
///
/// // Send mailable
/// await Mail.send(WelcomeMail(user));
///
/// // Queue mailable
/// await Mail.queue(WelcomeMail(user));
/// ```
class Mail {
  /// Gets the mail manager instance.
  static MailManager get manager => Khadem.container.resolve<MailManager>();

  /// Gets a mailer instance.
  ///
  /// [name] is the optional transport name. If not provided, uses default.
  static MailerInterface mailer([String? name]) => manager.mailer(name);

  // Convenience methods that proxy to the default mailer

  /// Sets the recipient(s) of the email.
  static MailerInterface to(dynamic addresses) => manager.to(addresses);

  /// Sets the CC recipient(s).
  static MailerInterface cc(dynamic addresses) => manager.cc(addresses);

  /// Sets the BCC recipient(s).
  static MailerInterface bcc(dynamic addresses) => manager.bcc(addresses);

  /// Sets the reply-to address.
  static MailerInterface replyTo(String address, [String? name]) =>
      manager.replyTo(address, name);

  /// Sets the email subject.
  static MailerInterface subject(String subject) => manager.subject(subject);

  /// Sets the sender (from address).
  static MailerInterface from(String address, [String? name]) =>
      manager.from(address, name);

  /// Sets the plain text body.
  static MailerInterface text(String content) => manager.text(content);

  /// Sets the HTML body.
  static MailerInterface html(String content) => manager.html(content);

  /// Renders a view template for the email body.
  static Future<MailerInterface> view(
    String viewName, [
    Map<String, dynamic>? data,
  ]) =>
      manager.view(viewName, data);

  /// Attaches a file.
  static MailerInterface attach(
    String path, {
    String? name,
    String? mimeType,
  }) =>
      manager.attach(path, name: name, mimeType: mimeType);

  /// Attaches raw data.
  static MailerInterface attachData(
    List<int> data,
    String name, {
    String? mimeType,
  }) =>
      manager.attachData(data, name, mimeType: mimeType);

  /// Embeds an inline image.
  static MailerInterface embed(String path, String cid) =>
      manager.embed(path, cid);

  /// Sets a custom header.
  static MailerInterface header(String name, String value) =>
      manager.header(name, value);

  /// Sets the email priority.
  static MailerInterface priority(int priority) => manager.priority(priority);

  /// Sends a mailable.
  static Future<bool> send(Mailable mailable) => manager.sendMailable(mailable);

  /// Queues a mailable.
  static Future<void> queue(Mailable mailable, [Duration? delay]) =>
      manager.queueMailable(mailable, delay);

  /// Tests a transport connection.
  static Future<bool> test([String? transport]) =>
      manager.testTransport(transport);

  /// Gets list of available transports.
  static List<String> get transports => manager.availableTransports;
}

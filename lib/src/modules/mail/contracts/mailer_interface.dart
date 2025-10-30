import 'mail_message_interface.dart';
import 'mailable.dart';

/// Interface for mail sending operations.
///
/// Defines the contract for sending emails through various mail drivers.
/// Implementations should handle the actual email transmission.
///
/// Example:
/// ```dart
/// final mailer = Mail.mailer();
/// await mailer.to('user@example.com')
///     .subject('Welcome!')
///     .text('Welcome to our app')
///     .send();
/// ```
abstract interface class MailerInterface {
  /// Sets the recipient(s) of the email.
  ///
  /// [addresses] can be:
  /// - A single email address as String
  /// - A Map with 'email' and optional 'name' keys
  /// - A List of either of the above
  ///
  /// Example:
  /// ```dart
  /// mailer.to('user@example.com');
  /// mailer.to({'email': 'user@example.com', 'name': 'John Doe'});
  /// mailer.to(['user1@example.com', 'user2@example.com']);
  /// ```
  MailerInterface to(dynamic addresses);

  /// Sets the CC (Carbon Copy) recipient(s).
  MailerInterface cc(dynamic addresses);

  /// Sets the BCC (Blind Carbon Copy) recipient(s).
  MailerInterface bcc(dynamic addresses);

  /// Sets the reply-to address.
  MailerInterface replyTo(String address, [String? name]);

  /// Sets the email subject.
  MailerInterface subject(String subject);

  /// Sets the email sender (from address).
  ///
  /// If not set, uses the default from address from configuration.
  MailerInterface from(String address, [String? name]);

  /// Sets the plain text body of the email.
  MailerInterface text(String content);

  /// Sets the HTML body of the email.
  MailerInterface html(String content);

  /// Renders a view template for the email body.
  ///
  /// The view is rendered using the Khadem view system.
  ///
  /// Example:
  /// ```dart
  /// await mailer.view('emails.welcome', {'name': 'John'});
  /// ```
  Future<MailerInterface> view(String viewName, [Map<String, dynamic>? data]);

  /// Attaches a file to the email.
  ///
  /// [path] is the file path on disk.
  /// [name] is the optional display name for the attachment.
  /// [mimeType] is the optional MIME type.
  MailerInterface attach(String path, {String? name, String? mimeType});

  /// Attaches raw data as a file.
  ///
  /// [data] is the file content as bytes.
  /// [name] is the attachment filename.
  /// [mimeType] is the MIME type of the attachment.
  MailerInterface attachData(
    List<int> data,
    String name, {
    String? mimeType,
  });

  /// Embeds an inline image in the email.
  ///
  /// [path] is the image file path.
  /// [cid] is the Content-ID to reference in HTML (e.g., 'logo').
  ///
  /// In HTML: <img src="cid:logo">
  MailerInterface embed(String path, String cid);

  /// Sets a custom header.
  MailerInterface header(String name, String value);

  /// Sets the email priority.
  ///
  /// [priority] should be 1 (highest), 3 (normal), or 5 (lowest).
  MailerInterface priority(int priority);

  /// Sends the email immediately.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> send();

  /// Queues the email for asynchronous sending.
  ///
  /// [delay] is an optional delay before sending.
  Future<void> queue([Duration? delay]);

  /// Sends a Mailable instance.
  ///
  /// Example:
  /// ```dart
  /// await mailer.sendMailable(WelcomeMail(user));
  /// ```
  Future<bool> sendMailable(Mailable mailable);

  /// Queues a Mailable instance.
  Future<void> queueMailable(Mailable mailable, [Duration? delay]);

  /// Creates a new message builder.
  ///
  /// This allows creating multiple independent messages from the same mailer.
  MailMessageInterface message();

  /// Gets the underlying transport/driver name.
  String get driverName;
}

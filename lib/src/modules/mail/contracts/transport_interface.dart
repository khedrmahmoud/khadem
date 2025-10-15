import 'mail_message_interface.dart';

/// Interface for mail transport drivers.
///
/// Implementations handle the actual sending of emails through
/// various services (SMTP, SES, Mailgun, etc.).
abstract interface class TransportInterface {
  /// Sends an email message.
  ///
  /// Returns true if successful, false otherwise.
  /// May throw exceptions on critical failures.
  Future<bool> send(MailMessageInterface message);

  /// Gets the transport name/identifier.
  String get name;

  /// Tests the transport connection.
  ///
  /// Returns true if the transport is properly configured and can connect.
  Future<bool> test();
}

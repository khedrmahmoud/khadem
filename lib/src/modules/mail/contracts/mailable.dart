import 'mailer_interface.dart';

/// Base class for mailable objects.
///
/// Mailables provide a clean, object-oriented way to build emails.
/// Extend this class and implement the build() method to define your email.
///
/// Example:
/// ```dart
/// class WelcomeMail extends Mailable {
///   final User user;
///
///   WelcomeMail(this.user);
///
///   @override
///   Future<void> build(MailerInterface mailer) async {
///     await mailer
///         .to(user.email)
///         .subject('Welcome to ${user.name}!')
///         .view('emails.welcome', {'user': user});
///   }
/// }
///
/// // Usage:
/// await Mail.send(WelcomeMail(user));
/// ```
abstract class Mailable {
  /// Builds the email message.
  ///
  /// Use the provided [mailer] to configure the email.
  Future<void> build(MailerInterface mailer);

  /// Determines if this mailable should be queued.
  ///
  /// Override to return true if this mail should always be queued.
  bool get shouldQueue => false;

  /// The delay before sending when queued.
  ///
  /// Only applies when shouldQueue is true.
  Duration? get queueDelay => null;

  /// The queue connection to use.
  ///
  /// Returns null to use default queue.
  String? get queueConnection => null;

  /// The display name for this mailable (used in logs).
  String get displayName => runtimeType.toString();

  /// Hook called before the mailable is sent.
  ///
  /// Override to perform actions before sending.
  Future<void> beforeSend() async {}

  /// Hook called after the mailable is sent successfully.
  ///
  /// Override to perform actions after sending.
  Future<void> afterSend() async {}

  /// Hook called if sending fails.
  ///
  /// Override to handle send failures.
  Future<void> onError(dynamic error, StackTrace stackTrace) async {}
}

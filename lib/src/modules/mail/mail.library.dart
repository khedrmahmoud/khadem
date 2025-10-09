/// Khadem Mail Module
///
/// Provides a unified, fluent API for sending emails through multiple
/// mail services (SMTP, SES, Mailgun, etc.).
///
/// ## Features
///
/// - Multiple mail drivers (SMTP, SES, Mailgun, Log, Array)
/// - Fluent API for building emails
/// - Mailable classes for clean email composition
/// - View template rendering
/// - Attachments and embedded images
/// - Queue integration for async sending
/// - Testing utilities
///
/// ## Basic Usage
///
/// ```dart
/// // Send simple email
/// await Mail.to('user@example.com')
///     .subject('Welcome!')
///     .text('Welcome to our app')
///     .send();
///
/// // Send with HTML view
/// await Mail.to('user@example.com')
///     .subject('Welcome!')
///     .view('emails.welcome', {'name': 'John'})
///     .send();
///
/// // Send mailable
/// await Mail.send(WelcomeMail(user));
///
/// // Queue for async sending
/// await Mail.queue(NewsletterMail(users));
/// ```
///
/// ## Mailable Example
///
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
///         .subject('Welcome ${user.name}!')
///         .view('emails.welcome', {'user': user})
///         .attach('assets/welcome.pdf');
///   }
/// }
/// ```
library;

export 'index.dart';

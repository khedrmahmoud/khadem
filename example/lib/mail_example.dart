import 'dart:convert';
import 'package:khadem/khadem.dart';
import 'app/mailables/password_reset_mail.dart';
import 'app/mailables/welcome_mail.dart';

/// Demonstrates sending emails using the Khadem mail module.
///
/// Run with: dart run example/lib/mail_example.dart
void main() async {
  print('🔧 Mail Module Examples\n');

  // Example 1: Simple email
  await simpleEmailExample();

  // Example 2: HTML email
  await htmlEmailExample();

  // Example 3: Email with attachments
  await attachmentExample();

  // Example 4: Using mailables
  await mailableExample();

  // Example 5: Queued emails
  await queuedEmailExample();

  print('\n✅ All examples completed!');
}

/// Example 1: Send a simple plain text email
Future<void> simpleEmailExample() async {
  print('📧 Example 1: Simple Email');
  
  try {
    final transport = ArrayTransport(); // Use array transport for testing
    final mailer = Mailer(transport);

    await mailer
        .to('user@example.com')
        .from('noreply@example.com', 'Khadem App')
        .subject('Welcome!')
        .text('Thank you for joining our platform.')
        .send();

    print('   ✓ Simple email sent successfully');
    print('   Sent to: ${transport.lastSent?.to.first.email}\n');
  } catch (e) {
    print('   ✗ Error: $e\n');
  }
}

/// Example 2: Send an HTML email with fallback
Future<void> htmlEmailExample() async {
  print('📧 Example 2: HTML Email');
  
  try {
    final transport = ArrayTransport();
    final mailer = Mailer(transport);

    await mailer
        .to('user@example.com')
        .subject('Newsletter - October 2025')
        .html('''
          <html>
            <body style="font-family: Arial, sans-serif;">
              <h1 style="color: #4CAF50;">Monthly Newsletter</h1>
              <p>Here are this month's highlights:</p>
              <ul>
                <li>New mail module released! 🎉</li>
                <li>Performance improvements</li>
                <li>Bug fixes and updates</li>
              </ul>
            </body>
          </html>
        ''')
        .text('Monthly Newsletter - October 2025\n\nHighlights:\n- New mail module\n- Performance improvements\n- Bug fixes')
        .send();

    print('   ✓ HTML email sent successfully');
    print('   Has HTML: ${transport.lastSent?.htmlBody != null}');
    print('   Has Text: ${transport.lastSent?.textBody != null}\n');
  } catch (e) {
    print('   ✗ Error: $e\n');
  }
}

/// Example 3: Send email with attachments
Future<void> attachmentExample() async {
  print('📧 Example 3: Email with Attachments');
  
  try {
    final transport = ArrayTransport();
    final mailer = Mailer(transport);

    // Create sample data
    final reportData = utf8.encode('Sample Report Data\nGenerated: ${DateTime.now()}');

    await mailer
        .to('user@example.com')
        .subject('Monthly Report')
        .text('Please find the monthly report attached.')
        .attachData(reportData, 'report.txt', mimeType: 'text/plain')
        .send();

    print('   ✓ Email with attachment sent successfully');
    print('   Attachments: ${transport.lastSent?.attachments.length}');
    print('   Filename: ${transport.lastSent?.attachments.first.filename}\n');
  } catch (e) {
    print('   ✗ Error: $e\n');
  }
}

/// Example 4: Send using Mailable class
Future<void> mailableExample() async {
  print('📧 Example 4: Using Mailable Class');
  
  try {
    final transport = ArrayTransport();
    final mailer = Mailer(transport);

    // Create a welcome email
    final welcomeEmail = WelcomeMail(
      userEmail: 'newuser@example.com',
      userName: 'John Doe',
    );

    await mailer.sendMailable(welcomeEmail);

    print('   ✓ Mailable sent successfully');
    print('   Subject: ${transport.lastSent?.subject}');
    print('   To: ${transport.lastSent?.to.first.email}\n');
  } catch (e) {
    print('   ✗ Error: $e\n');
  }
}

/// Example 5: Queue emails for async sending
Future<void> queuedEmailExample() async {
  print('📧 Example 5: Queued Email');
  
  try {
    // This would normally queue the email
    final passwordReset = PasswordResetMail(
      email: 'user@example.com',
      resetToken: 'abc123token',
      userName: 'Jane Smith',
    );

    print('   ✓ Password reset email configured');
    print('   Should queue: ${passwordReset.shouldQueue}');
    print('   Queue delay: ${passwordReset.queueDelay?.inSeconds} seconds\n');
  } catch (e) {
    print('   ✗ Error: $e\n');
  }
}

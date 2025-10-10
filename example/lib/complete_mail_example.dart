import 'package:khadem/khadem.dart';
import 'app/mailables/invoice_mail.dart';
import 'app/mailables/password_reset_mail.dart';
import 'app/mailables/welcome_mail.dart';

/// Demonstrates the complete mail module integration with Khadem framework.
///
/// This example shows:
/// - Loading mail configuration from config
/// - Using different mail transports (log, array, smtp)
/// - Sending emails through the Mail facade
/// - Using Mailable classes
/// - Queuing emails
///
/// Run with: dart run example/lib/complete_mail_example.dart
void main() async {
  print('📬 Complete Mail Module Example\n');
  print('═' * 60);

  // Initialize Khadem application
  final app = await initializeApp();

  // Example 1: Using Mail facade with default transport
  await example1_MailFacade(app);

  // Example 2: Switching between transports
  await example2_MultipleTransports(app);

  // Example 3: Sending mailables
  await example3_Mailables(app);

  // Example 4: Testing emails
  await example4_Testing(app);

  // Example 5: Production SMTP usage
  await example5_ProductionSMTP(app);

  print('\n═' * 60);
  print('✅ All examples completed successfully!\n');
}

/// Initialize Khadem application with mail configuration
Future<Khadem> initializeApp() async {
  print('⚙️  Initializing Khadem application...');

  final app = await Khadem.init(
    environment: 'development',
    providers: [
      // Add MailServiceProvider to register mail services
      MailServiceProvider(),
    ],
  );

  print('✓ Application initialized\n');
  return app;
}

/// Example 1: Using Mail facade
Future<void> example1_MailFacade(Khadem app) async {
  print('📧 Example 1: Using Mail Facade');
  print('─' * 60);

  try {
    // Get mail manager from container
    final mailManager = app.container.resolve<MailManager>();

    // Send a simple email using fluent API
    await mailManager
        .to('user@example.com')
        .subject('Hello from Khadem!')
        .text('This is a test email from the Khadem mail module.')
        .html('<h1>Hello!</h1><p>This is a test email from the Khadem mail module.</p>')
        .send();

    print('✓ Email sent successfully via default transport');
    print('  Transport: ${mailManager.defaultMailer}');
  } catch (e) {
    print('✗ Error: $e');
  }

  print('');
}

/// Example 2: Using different transports
Future<void> example2_MultipleTransports(Khadem app) async {
  print('📧 Example 2: Multiple Mail Transports');
  print('─' * 60);

  try {
    final mailManager = app.container.resolve<MailManager>();

    // Send via log transport (for development)
    print('Sending via LOG transport...');
    await mailManager
        .mailer('log')
        .to('dev@example.com')
        .subject('Development Email')
        .text('This email is logged, not sent.')
        .send();
    print('✓ Logged email');

    // Send via array transport (for testing)
    print('\nSending via ARRAY transport...');
    final arrayMailer = mailManager.mailer('array');
    await arrayMailer
        .to('test@example.com')
        .subject('Test Email')
        .text('This email is stored in memory.')
        .send();
    print('✓ Email stored in array transport');

    // Access array transport to check sent emails
    final arrayTransport = arrayMailer as Mailer;
    print('  Total emails in array: stored');
  } catch (e) {
    print('✗ Error: $e');
  }

  print('');
}

/// Example 3: Sending Mailable classes
Future<void> example3_Mailables(Khadem app) async {
  print('📧 Example 3: Using Mailable Classes');
  print('─' * 60);

  try {
    final mailManager = app.container.resolve<MailManager>();

    // Send welcome email
    print('Sending welcome email...');
    final welcomeMail = WelcomeMail(
      userEmail: 'newuser@example.com',
      userName: 'John Doe',
    );
    await mailManager.sendMailable(welcomeMail);
    print('✓ Welcome email sent');

    // Send password reset email (queued)
    print('\nSending password reset email (queued)...');
    final resetMail = PasswordResetMail(
      email: 'user@example.com',
      resetToken: 'abc123xyz789',
      userName: 'Jane Smith',
    );
    print('  Should queue: ${resetMail.shouldQueue}');
    print('  Queue delay: ${resetMail.queueDelay?.inSeconds}s');
    await mailManager.sendMailable(resetMail);
    print('✓ Password reset email queued');

    // Send invoice email with attachment
    print('\nSending invoice email...');
    final invoiceMail = InvoiceMail(
      email: 'customer@example.com',
      customerName: 'Bob Wilson',
      invoiceNumber: 'INV-2025-001',
      amount: '\$99.99',
      pdfPath: 'storage/invoices/sample.pdf',
    );
    await mailManager.sendMailable(invoiceMail);
    print('✓ Invoice email sent');
  } catch (e) {
    print('✗ Error: $e');
  }

  print('');
}

/// Example 4: Testing emails with ArrayTransport
Future<void> example4_Testing(Khadem app) async {
  print('📧 Example 4: Testing Emails');
  print('─' * 60);

  try {
    final mailManager = app.container.resolve<MailManager>();
    final testMailer = mailManager.mailer('array');

    // Send test emails
    await testMailer
        .to('admin@example.com')
        .subject('Admin Alert')
        .text('This is an admin alert.')
        .send();

    await testMailer
        .to('user@example.com')
        .subject('User Notification')
        .text('This is a user notification.')
        .send();

    print('✓ Test emails sent to array transport');
    print('  You can now assert on the sent emails in tests');
  } catch (e) {
    print('✗ Error: $e');
  }

  print('');
}

/// Example 5: Production SMTP usage
Future<void> example5_ProductionSMTP(Khadem app) async {
  print('📧 Example 5: Production SMTP (Configuration Only)');
  print('─' * 60);

  try {
    final config = app.container.resolve<ConfigInterface>();

    // Show SMTP configuration
    final smtpHost = config.get<String>('mail.smtp.host');
    final smtpPort = config.get<int>('mail.smtp.port');
    final smtpEncryption = config.get<String>('mail.smtp.encryption');

    print('SMTP Configuration:');
    print('  Host: $smtpHost');
    print('  Port: $smtpPort');
    print('  Encryption: $smtpEncryption');
    print('  Status: Ready (set MAIL_DRIVER=smtp in .env to use)');
    print('');
    print('To send via SMTP in production:');
    print('  1. Configure SMTP credentials in .env');
    print('  2. Set MAIL_DRIVER=smtp');
    print('  3. Restart application');
    print('  4. Emails will be sent via SMTP transport');
  } catch (e) {
    print('✗ Error: $e');
  }

  print('');
}

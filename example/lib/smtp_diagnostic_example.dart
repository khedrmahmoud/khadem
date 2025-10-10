import 'package:khadem/khadem.dart';

/// Example script to diagnose SMTP connection issues.
///
/// Usage:
/// ```bash
/// dart run example/lib/smtp_diagnostic_example.dart
/// ```
Future<void> main() async {
  // Initialize the framework (to load environment)
  await Khadem.init(environment: 'development');

  // Get SMTP configuration from environment
  final smtpConfig = SmtpConfig(
    host: Khadem.env.getOrDefault('SMTP_HOST', 'smtp.gmail.com'),
    port: Khadem.env.getInt('SMTP_PORT', defaultValue: 587),
    username: Khadem.env.get('SMTP_USERNAME'),
    password: Khadem.env.get('SMTP_PASSWORD'),
    encryption: Khadem.env.getOrDefault('SMTP_ENCRYPTION', 'tls'),
    timeout: Khadem.env.getInt('SMTP_TIMEOUT', defaultValue: 30),
  );

  print('Testing SMTP configuration:');
  print('Host: ${smtpConfig.host}');
  print('Port: ${smtpConfig.port}');
  print('Encryption: ${smtpConfig.encryption}');
  print('Timeout: ${smtpConfig.timeout}s');
  print('');

  // Run diagnostics
  await SmtpDiagnostics.quickTest(smtpConfig);

  // Also test common SMTP servers
  print('\n=== Testing Common SMTP Servers ===\n');

  // Gmail
  print('Testing Gmail SMTP...');
  final gmailConfig = SmtpConfig(
    host: 'smtp.gmail.com',
    port: 587,
    encryption: 'tls',
    timeout: 10,
  );
  final gmailReport = await SmtpDiagnostics.testConnection(gmailConfig);
  print('Gmail: ${gmailReport.summary}\n');

  // Outlook/Office365
  print('Testing Outlook SMTP...');
  final outlookConfig = SmtpConfig(
    host: 'smtp.office365.com',
    port: 587,
    encryption: 'tls',
    timeout: 10,
  );
  final outlookReport = await SmtpDiagnostics.testConnection(outlookConfig);
  print('Outlook: ${outlookReport.summary}\n');

  // Mailtrap (testing service)
  print('Testing Mailtrap SMTP...');
  final mailtrapConfig = SmtpConfig(
    host: 'smtp.mailtrap.io',
    port: 2525,
    encryption: 'tls',
    timeout: 10,
  );
  final mailtrapReport = await SmtpDiagnostics.testConnection(mailtrapConfig);
  print('Mailtrap: ${mailtrapReport.summary}\n');
}

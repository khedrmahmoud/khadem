# SMTP Connection Troubleshooting Guide

## Error: Connection Timeout

If you're seeing this error:
```
MailTransportException: Failed to send email via SMTP: MailTransportException: 
Failed to connect to SMTP server: SocketException: The semaphore timeout period has expired.
```

This means the SMTP server is not responding within the configured timeout period.

## Quick Diagnostic Steps

### 1. Run the Diagnostic Tool

Run the included diagnostic script:

```bash
dart run example/lib/smtp_diagnostic_example.dart
```

This will test your SMTP configuration and provide detailed feedback.

### 2. Common SMTP Settings

Make sure you're using the correct settings for your email provider:

#### Gmail
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_ENCRYPTION=tls
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-specific-password  # NOT your regular password!
```

**Important**: Gmail requires an [App Password](https://myaccount.google.com/apppasswords), not your regular password.

#### Outlook/Office365
```env
SMTP_HOST=smtp.office365.com
SMTP_PORT=587
SMTP_ENCRYPTION=tls
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
```

#### Mailtrap (Testing)
```env
SMTP_HOST=smtp.mailtrap.io
SMTP_PORT=2525
SMTP_ENCRYPTION=tls
SMTP_USERNAME=your-mailtrap-username
SMTP_PASSWORD=your-mailtrap-password
```

#### SendGrid
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_ENCRYPTION=tls
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

### 3. Check Firewall Settings

The SMTP port must be allowed through your firewall:

**Windows Firewall:**
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Outbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter your SMTP port (e.g., 587)
6. Allow the connection
7. Apply to all profiles
8. Name it "SMTP Outbound"

**Linux (iptables):**
```bash
sudo iptables -A OUTPUT -p tcp --dport 587 -j ACCEPT
```

**MacOS:**
```bash
# Usually no firewall blocks outbound connections
# If using Little Snitch, add a rule for your app
```

### 4. Test Port Connectivity

#### Using telnet (Windows/Mac/Linux):
```bash
telnet smtp.gmail.com 587
```

If it connects, you should see:
```
220 smtp.gmail.com ESMTP
```

Press `Ctrl+C` to exit.

#### Using PowerShell (Windows):
```powershell
Test-NetConnection -ComputerName smtp.gmail.com -Port 587
```

You should see `TcpTestSucceeded : True`

#### Using nc (Mac/Linux):
```bash
nc -zv smtp.gmail.com 587
```

### 5. Increase Timeout

If your network is slow, increase the timeout in your `.env`:

```env
SMTP_TIMEOUT=60  # Increase from default 30 seconds
```

### 6. Try Different Ports

Some networks block certain ports. Try these alternatives:

| Port | Encryption | Common Use |
|------|------------|------------|
| 25   | None/TLS   | Standard (often blocked) |
| 587  | TLS        | Recommended for submission |
| 465  | SSL        | Legacy SSL port |
| 2525 | TLS        | Alternative (Mailtrap, etc.) |

Example for SSL on port 465:
```env
SMTP_PORT=465
SMTP_ENCRYPTION=ssl
```

### 7. Check if SMTP is Blocked

Some ISPs and corporate networks block SMTP ports:

1. Try from a different network (mobile hotspot, home, coffee shop)
2. Contact your ISP or network admin
3. Use a VPN to bypass blocks

### 8. Verify Credentials

Test your credentials manually:

```bash
# Base64 encode your credentials
echo -n "your-email@gmail.com" | base64
# Output: eW91ci1lbWFpbEBnbWFpbC5jb20=

echo -n "your-password" | base64
# Output: eW91ci1wYXNzd29yZA==
```

Then test with telnet:
```bash
telnet smtp.gmail.com 587
EHLO localhost
STARTTLS
AUTH LOGIN
[paste base64 username]
[paste base64 password]
```

### 9. Use Alternative Transports

If SMTP continues to fail, use an API-based transport:

#### Mailgun
```env
MAIL_DRIVER=mailgun
MAILGUN_DOMAIN=mg.yourdomain.com
MAILGUN_API_KEY=key-xxxxx
```

#### Amazon SES
```env
MAIL_DRIVER=ses
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_DEFAULT_REGION=us-east-1
```

#### Postmark
```env
MAIL_DRIVER=postmark
POSTMARK_SERVER_TOKEN=your-server-token
```

These use HTTPS (port 443) which is rarely blocked.

### 10. For Development: Use Log Driver

For testing without sending real emails:

```env
MAIL_DRIVER=log
```

This will log emails instead of sending them.

## Programmatic Diagnostic

You can also run diagnostics programmatically:

```dart
import 'package:khadem/khadem.dart';

void main() async {
  final config = SmtpConfig(
    host: 'smtp.gmail.com',
    port: 587,
    encryption: 'tls',
    timeout: 30,
  );

  final report = await SmtpDiagnostics.testConnection(config);
  
  if (report.isHealthy) {
    print('✓ SMTP server is reachable!');
  } else {
    print('✗ Issue: ${report.summary}');
    print(SmtpDiagnostics.generateDiagnosticMessage(report));
  }
}
```

## Common Error Solutions

### "Connection refused"
- SMTP server is down or not running
- Wrong port number
- Firewall blocking connection

### "Connection timeout"
- Network connectivity issues
- Firewall blocking outbound connections
- SMTP server not responding
- Wrong hostname

### "SSL/TLS error"
- Wrong encryption setting (use 'tls' for port 587, 'ssl' for port 465)
- Outdated SSL certificates
- Security software interfering

### "Authentication failed"
- Wrong username or password
- Need app-specific password (Gmail)
- Account not enabled for SMTP access
- 2FA enabled but no app password

## Still Having Issues?

1. Check your email provider's SMTP documentation
2. Try the diagnostic tool: `dart run example/lib/smtp_diagnostic_example.dart`
3. Test with Mailtrap.io (free testing SMTP)
4. Switch to an API transport (Mailgun, SES, Postmark)
5. Check application logs for detailed error messages

## Quick Test with Mailtrap

1. Sign up at https://mailtrap.io (free)
2. Get your credentials from the inbox settings
3. Update your `.env`:

```env
SMTP_HOST=smtp.mailtrap.io
SMTP_PORT=2525
SMTP_ENCRYPTION=tls
SMTP_USERNAME=your-mailtrap-username
SMTP_PASSWORD=your-mailtrap-password
```

4. Send a test email - it will appear in your Mailtrap inbox!

This guarantees the framework works and helps isolate provider-specific issues.

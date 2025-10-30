# Khadem Mail Module

Complete email sending solution for the Khadem framework with support for multiple mail drivers and professional email templates.

## Features

- ✅ **Multiple Mail Drivers**
  - SMTP (production email sending with TLS/SSL)
  - Mailgun (cloud email API)
  - Amazon SES (AWS Simple Email Service)
  - Postmark (transactional email service)
  - Log (development logging)
  - Array (testing with assertions)
  
- ✅ **Rich Email Features**
  - HTML and plain text emails
  - File attachments (path or raw data)
  - Inline embedded images
  - CC, BCC, Reply-To
  - Custom headers and priority
  - Queue integration for async sending

- ✅ **Mailable Classes**
  - Object-oriented email composition
  - Lifecycle hooks (beforeSend, afterSend, onError)
  - Queue support with delays
  - Reusable email templates

- ✅ **Testing Support**
  - ArrayTransport for in-memory email storage
  - Assertions: `wasSentTo()`, `wasSentWithSubject()`, `findSent()`
  - Full access to sent messages

## Quick Start

### 1. Installation

The mail module is included in Khadem. Register the service provider:

```dart
final app = await Khadem.init(
  environment: 'development',
  providers: [
    MailServiceProvider(),
  ],
);
```

### 2. Configuration

Add to your `config/app.dart`:

```dart
'mail': {
  'default': env.getOrDefault('MAIL_DRIVER', 'log'),
  'from': {
    'address': env.getOrDefault('MAIL_FROM_ADDRESS', 'noreply@example.com'),
    'name': env.getOrDefault('MAIL_FROM_NAME', 'Khadem Framework'),
  },
  'smtp': {
    'host': env.getOrDefault('SMTP_HOST', 'smtp.mailtrap.io'),
    'port': env.getInt('SMTP_PORT', defaultValue: 2525),
    'username': env.get('SMTP_USERNAME'),
    'password': env.get('SMTP_PASSWORD'),
    'encryption': env.getOrDefault('SMTP_ENCRYPTION', 'tls'),
    'timeout': env.getInt('SMTP_TIMEOUT', defaultValue: 30),
  },
  'mailgun': {
    'domain': env.get('MAILGUN_DOMAIN'),
    'api_key': env.get('MAILGUN_API_KEY'),
    'endpoint': env.getOrDefault('MAILGUN_ENDPOINT', 'https://api.mailgun.net'),
  },
  'ses': {
    'access_key_id': env.get('AWS_ACCESS_KEY_ID'),
    'secret_access_key': env.get('AWS_SECRET_ACCESS_KEY'),
    'region': env.getOrDefault('AWS_DEFAULT_REGION', 'us-east-1'),
    'configuration_set': env.get('AWS_SES_CONFIGURATION_SET'),
  },
  'postmark': {
    'server_token': env.get('POSTMARK_SERVER_TOKEN'),
    'message_stream': env.getOrDefault('POSTMARK_MESSAGE_STREAM', 'outbound'),
  },
},
```

Add to your `.env`:

```env
MAIL_DRIVER=log
MAIL_FROM_ADDRESS=noreply@example.com
MAIL_FROM_NAME="Khadem Framework"

# SMTP Configuration
SMTP_HOST=smtp.mailtrap.io
SMTP_PORT=2525
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
SMTP_ENCRYPTION=tls
SMTP_TIMEOUT=30

# Mailgun Configuration (optional)
MAILGUN_DOMAIN=mg.example.com
MAILGUN_API_KEY=key-xxxxx
MAILGUN_ENDPOINT=https://api.mailgun.net

# Amazon SES Configuration (optional)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_DEFAULT_REGION=us-east-1
AWS_SES_CONFIGURATION_SET=my-config-set

# Postmark Configuration (optional)
POSTMARK_SERVER_TOKEN=your-server-token
POSTMARK_MESSAGE_STREAM=outbound
```

### 3. Send Your First Email

```dart
final mailManager = container.resolve<MailManager>();

await mailManager
    .to('user@example.com')
    .subject('Welcome!')
    .text('Thank you for joining us.')
    .html('<h1>Welcome!</h1><p>Thank you for joining us.</p>')
    .send();
```

## Usage Examples

### Simple Email

```dart
await mailManager
    .to('user@example.com')
    .from('sender@example.com', 'My App')
    .subject('Hello World')
    .text('This is a plain text email.')
    .send();
```

### HTML Email with Fallback

```dart
await mailManager
    .to('user@example.com')
    .subject('Newsletter')
    .html('<h1>Newsletter</h1><p>Latest updates...</p>')
    .text('Newsletter - Latest updates...')
    .send();
```

### Email with Attachments

```dart
// Attach file from path
await mailManager
    .to('user@example.com')
    .subject('Invoice')
    .text('Please find your invoice attached.')
    .attach('/path/to/invoice.pdf', name: 'invoice.pdf')
    .send();

// Attach raw data
final data = utf8.encode('Report data');
await mailManager
    .to('user@example.com')
    .subject('Report')
    .attachData(data, 'report.txt', mimeType: 'text/plain')
    .send();
```

### Email with Inline Images

```dart
await mailManager
    .to('user@example.com')
    .subject('Welcome')
    .html('<h1>Welcome!</h1><img src="cid:logo">')
    .embed('/path/to/logo.png', 'logo')
    .send();
```

### Multiple Recipients

```dart
await mailManager
    .to('user1@example.com')
    .to('user2@example.com')
    .cc('manager@example.com')
    .bcc('admin@example.com')
    .subject('Team Update')
    .text('Update for the team.')
    .send();
```

### Using Mailable Classes

Create a mailable:

```dart
class WelcomeMail extends Mailable {
  final String userEmail;
  final String userName;

  WelcomeMail({required this.userEmail, required this.userName});

  @override
  Future<void> build(MailerInterface mailer) async {
    mailer
        .to(userEmail)
        .subject('Welcome to Our App!')
        .html(_buildHtmlContent())
        .text(_buildTextContent());
  }

  String _buildHtmlContent() {
    return '''
      <h1>Welcome $userName!</h1>
      <p>We're excited to have you on board.</p>
    ''';
  }

  String _buildTextContent() {
    return 'Welcome $userName!\n\nWe\'re excited to have you on board.';
  }
}
```

Send the mailable:

```dart
final welcome = WelcomeMail(
  userEmail: 'user@example.com',
  userName: 'John Doe',
);

await mailManager.sendMailable(welcome);
```

### Queued Emails

```dart
class PasswordResetMail extends Mailable {
  @override
  bool get shouldQueue => true;

  @override
  Duration? get queueDelay => Duration(seconds: 5);

  @override
  Future<void> build(MailerInterface mailer) async {
    // Build email...
  }
}

// This will be queued automatically
await mailManager.sendMailable(PasswordResetMail(...));
```

### Using Different Transports

```dart
// Use specific transport
await mailManager.mailer('smtp')
    .to('user@example.com')
    .subject('Via SMTP')
    .send();

await mailManager.mailer('log')
    .to('dev@example.com')
    .subject('Logged Email')
    .send();
```

## Testing

### Using ArrayTransport

```dart
// In your test setup
final transport = ArrayTransport();
final mailer = Mailer(transport);

// Send test email
await mailer
    .to('test@example.com')
    .subject('Test')
    .text('Test content')
    .send();

// Assert on sent emails
expect(transport.hasSent, isTrue);
expect(transport.wasSentTo('test@example.com'), isTrue);
expect(transport.wasSentWithSubject('Test'), isTrue);

// Check message details
final sent = transport.lastSent!;
expect(sent.to.first.email, equals('test@example.com'));
expect(sent.subject, equals('Test'));
```

### Test Helpers

```dart
// Find specific emails
final adminEmails = transport.findSent(
  (msg) => msg.to.any((addr) => addr.email.endsWith('@admin.com')),
);

// Get first/last sent
final firstEmail = transport.firstSent;
final lastEmail = transport.lastSent;

// Clear for next test
transport.clear();
```

## Configuration

### SMTP Configuration

```dart
'smtp': {
  'host': 'smtp.gmail.com',
  'port': 587,
  'username': 'your@gmail.com',
  'password': 'app-password',
  'encryption': 'tls', // tls, ssl, or none
  'timeout': 30,
}
```

### Mailgun Configuration

```dart
'mailgun': {
  'domain': 'mg.your-domain.com',
  'api_key': 'key-xxxxx',
  'endpoint': 'https://api.mailgun.net',
}
```

### Amazon SES Configuration

```dart
'ses': {
  'access_key_id': 'AKIAIOSFODNN7EXAMPLE',
  'secret_access_key': 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
  'region': 'us-east-1',
  'configuration_set': 'my-config-set', // optional
}
```

### Postmark Configuration

```dart
'postmark': {
  'server_token': 'your-server-token',
  'message_stream': 'outbound', // optional, defaults to 'outbound'
}
```

## Transport Comparison

| Feature | SMTP | Mailgun | SES | Postmark | Log | Array |
|---------|------|---------|-----|----------|-----|-------|
| **Best For** | Self-hosted | High volume | AWS ecosystem | Transactional | Development | Testing |
| **Cost** | Server costs | Pay-per-email | Very low | Per-email | Free | Free |
| **Setup** | Complex | Simple API | AWS setup | Simple API | None | None |
| **Delivery Speed** | Variable | Fast | Fast | Very fast | Instant | Instant |
| **Attachments** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Inline Images** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Analytics** | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Bounce Handling** | Manual | ✅ | ✅ | ✅ | ❌ | ❌ |

### Choosing a Transport

- **Development**: Use `log` transport to see emails in your logs
- **Testing**: Use `array` transport with assertions
- **Production - Self-hosted**: Use `smtp` with your mail server
- **Production - High volume**: Use `mailgun` for reliable delivery
- **Production - AWS**: Use `ses` for cost-effective sending
- **Production - Transactional**: Use `postmark` for fast delivery
  'region': 'us-east-1',
}
```

## Available Transports

| Transport | Purpose | Features |
|-----------|---------|----------|
| **SMTP** | Production | Full SMTP protocol, TLS/SSL, auth, attachments |
| **Log** | Development | Logs emails instead of sending |
| **Array** | Testing | Stores emails in memory for assertions |

## Examples

See the `example` directory for complete working examples:

- `mail_example.dart` - Basic mail operations
- `complete_mail_example.dart` - Full integration example
- `app/mailables/` - Example mailable classes
  - `welcome_mail.dart` - Welcome email template
  - `password_reset_mail.dart` - Password reset with queuing
  - `invoice_mail.dart` - Invoice with PDF attachment

## API Reference

### MailManager

- `to(addresses)` - Set recipients
- `cc(addresses)` - Set CC recipients
- `bcc(addresses)` - Set BCC recipients
- `from(address, name?)` - Set sender
- `replyTo(address, name?)` - Set reply-to
- `subject(subject)` - Set subject
- `text(content)` - Set plain text body
- `html(content)` - Set HTML body
- `attach(path, name?, mimeType?)` - Attach file
- `attachData(data, name, mimeType?)` - Attach raw data
- `embed(path, cid, mimeType?)` - Embed inline image
- `header(name, value)` - Add custom header
- `priority(1-5)` - Set priority (1=highest, 5=lowest)
- `send()` - Send immediately
- `queue(delay?)` - Queue for async sending
- `sendMailable(mailable)` - Send mailable
- `queueMailable(mailable, delay?)` - Queue mailable

### Mailable

- `build(mailer)` - Build the email (abstract)
- `beforeSend()` - Hook before sending
- `afterSend()` - Hook after sending
- `onError(error, stack)` - Hook on error
- `shouldQueue` - Should auto-queue (default: false)
- `queueDelay` - Delay before sending when queued
- `queueConnection` - Queue connection to use
- `displayName` - Display name for logging

## License

MIT License - see LICENSE file for details.

import 'package:khadem/khadem.dart' show Khadem;

class MailConfig {
  static final env = Khadem.env;

  static Map<String, dynamic> get config => {
        'default': env.getOrDefault('MAIL_DRIVER', 'log'),
        'from': {
          'address':
              env.getOrDefault('MAIL_FROM_ADDRESS', 'noreply@example.com'),
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
          'apiKey': env.get('MAILGUN_API_KEY'),
          'endpoint':
              env.getOrDefault('MAILGUN_ENDPOINT', 'https://api.mailgun.net'),
        },
        'ses': {
          'accessKeyId': env.get('SES_ACCESS_KEY_ID'),
          'secretAccessKey': env.get('SES_SECRET_ACCESS_KEY'),
          'region': env.getOrDefault('SES_REGION', 'us-east-1'),
        },
        'postmark': {
          'serverToken': env.get('POSTMARK_SERVER_TOKEN'),
          'messageStream':
              env.getOrDefault('POSTMARK_MESSAGE_STREAM', 'outbound'),
        },
      };
}

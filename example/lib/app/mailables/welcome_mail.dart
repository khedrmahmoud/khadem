import 'package:khadem/khadem.dart';

/// Welcome email sent to new users.
///
/// Example:
/// ```dart
/// final user = User(email: 'john@example.com', name: 'John Doe');
/// await Mail.send(WelcomeMail(user));
/// ```
class WelcomeMail extends Mailable {
  final String userEmail;
  final String userName;

  WelcomeMail({
    required this.userEmail,
    required this.userName,
  });

  @override
  Future<void> build(MailerInterface mailer) async {
    mailer
        .to(userEmail)
        .subject('Welcome to Khadem!')
        .html(_buildHtmlContent())
        .text(_buildTextContent());
  }

  String _buildHtmlContent() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background-color: #4CAF50;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px 5px 0 0;
        }
        .content {
            background-color: #f9f9f9;
            padding: 20px;
            border-radius: 0 0 5px 5px;
        }
        .button {
            display: inline-block;
            padding: 10px 20px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
        }
        .footer {
            margin-top: 20px;
            text-align: center;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to Khadem!</h1>
        </div>
        <div class="content">
            <h2>Hello $userName!</h2>
            <p>We're excited to have you on board. Khadem is a powerful Dart/Flutter framework that will help you build amazing applications.</p>
            
            <p>Here are some things you can do to get started:</p>
            <ul>
                <li>Check out our documentation</li>
                <li>Explore example projects</li>
                <li>Join our community</li>
            </ul>

            <a href="https://khadem.example.com/docs" class="button">Get Started</a>

            <p>If you have any questions, feel free to reach out to our support team.</p>

            <p>Best regards,<br>The Khadem Team</p>
        </div>
        <div class="footer">
            <p>This email was sent to $userEmail</p>
            <p>© 2025 Khadem Framework. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildTextContent() {
    return '''
Welcome to Khadem!

Hello $userName!

We're excited to have you on board. Khadem is a powerful Dart/Flutter framework that will help you build amazing applications.

Here are some things you can do to get started:
- Check out our documentation
- Explore example projects
- Join our community

Visit https://khadem.example.com/docs to get started.

If you have any questions, feel free to reach out to our support team.

Best regards,
The Khadem Team

This email was sent to $userEmail
© 2025 Khadem Framework. All rights reserved.
''';
  }
}

import 'package:khadem/khadem.dart';

/// Password reset email with reset link.
///
/// Example:
/// ```dart
/// final token = generateResetToken();
/// await Mail.send(PasswordResetMail(
///   email: 'john@example.com',
///   resetToken: token,
///   userName: 'John Doe',
/// ));
/// ```
class PasswordResetMail extends Mailable {
  final String email;
  final String resetToken;
  final String? userName;

  PasswordResetMail({
    required this.email,
    required this.resetToken,
    this.userName,
  });

  @override
  bool get shouldQueue => true; // Queue password resets for reliability

  @override
  Duration? get queueDelay =>
      const Duration(seconds: 5); // Small delay to prevent spam

  @override
  Future<void> build(MailerInterface mailer) async {
    final resetUrl = 'https://example.com/reset-password?token=$resetToken';

    mailer
        .to(email)
        .subject('Reset Your Password')
        .priority(2) // High priority
        .html(_buildHtmlContent(resetUrl))
        .text(_buildTextContent(resetUrl));
  }

  String _buildHtmlContent(String resetUrl) {
    final greeting = userName != null ? 'Hello $userName!' : 'Hello!';

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
            background-color: #f44336;
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
            padding: 12px 30px;
            background-color: #f44336;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
            font-weight: bold;
        }
        .warning {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 10px;
            margin: 15px 0;
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
            <h1>🔐 Password Reset Request</h1>
        </div>
        <div class="content">
            <h2>$greeting</h2>
            <p>We received a request to reset your password. Click the button below to create a new password:</p>

            <a href="$resetUrl" class="button">Reset Password</a>

            <div class="warning">
                <strong>⚠️ Security Notice:</strong><br>
                This link will expire in 1 hour for your security.<br>
                If you didn't request a password reset, please ignore this email.
            </div>

            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style="word-break: break-all; color: #666;">$resetUrl</p>

            <p>Best regards,<br>The Khadem Team</p>
        </div>
        <div class="footer">
            <p>This email was sent to $email</p>
            <p>© 2025 Khadem Framework. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildTextContent(String resetUrl) {
    final greeting = userName != null ? 'Hello $userName!' : 'Hello!';

    return '''
Password Reset Request

$greeting

We received a request to reset your password. Visit the link below to create a new password:

$resetUrl

⚠️ Security Notice:
- This link will expire in 1 hour for your security.
- If you didn't request a password reset, please ignore this email.

Best regards,
The Khadem Team

This email was sent to $email
© 2025 Khadem Framework. All rights reserved.
''';
  }

  @override
  Future<void> onError(dynamic error, StackTrace stackTrace) async {
    // Log the error for monitoring
    print('Failed to send password reset email to $email: $error');
  }
}

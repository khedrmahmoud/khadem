import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/mail_config.dart';
import '../contracts/mail_message_interface.dart';
import '../contracts/transport_interface.dart';
import '../exceptions/mail_exception.dart';

/// Mailgun API transport for sending emails via Mailgun service.
///
/// Mailgun is a popular transactional email service with a simple API.
/// This transport uses Mailgun's Messages API to send emails.
///
/// Example configuration:
/// ```dart
/// final config = MailgunConfig(
///   domain: 'mg.example.com',
///   apiKey: 'key-xxxx',
///   endpoint: 'https://api.mailgun.net',
/// );
/// final transport = MailgunTransport(config);
/// ```
///
/// See: https://documentation.mailgun.com/en/latest/api-sending.html
class MailgunTransport implements TransportInterface {
  final MailgunConfig _config;
  final http.Client _client;

  MailgunTransport(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get name => 'mailgun';

  @override
  Future<bool> send(MailMessageInterface message) async {
    try {
      // Validate message
      message.validate();

      // Build request
      final url =
          Uri.parse('${_config.endpoint}/v3/${_config.domain}/messages');

      // Prepare multipart request
      final request = http.MultipartRequest('POST', url);

      // Add authentication
      final credentials = base64Encode(utf8.encode('api:${_config.apiKey}'));
      request.headers['Authorization'] = 'Basic $credentials';

      // Add basic fields
      request.fields['from'] =
          message.from?.toString() ?? 'noreply@${_config.domain}';
      request.fields['subject'] = message.subject ?? '';

      // Add recipients
      for (final recipient in message.to) {
        request.fields['to'] = recipient.toString();
      }

      // Add CC recipients
      if (message.cc.isNotEmpty) {
        for (final recipient in message.cc) {
          request.fields['cc'] = recipient.toString();
        }
      }

      // Add BCC recipients
      if (message.bcc.isNotEmpty) {
        for (final recipient in message.bcc) {
          request.fields['bcc'] = recipient.toString();
        }
      }

      // Add reply-to
      if (message.replyTo != null) {
        request.fields['h:Reply-To'] = message.replyTo.toString();
      }

      // Add text body
      if (message.textBody != null) {
        request.fields['text'] = message.textBody!;
      }

      // Add HTML body
      if (message.htmlBody != null) {
        request.fields['html'] = message.htmlBody!;
      }

      // Add custom headers
      for (final entry in message.headers.entries) {
        request.fields['h:${entry.key}'] = entry.value;
      }

      // Add priority as custom header
      if (message.priority != 3) {
        request.fields['h:X-Priority'] = message.priority.toString();
      }

      // Add attachments
      for (final attachment in message.attachments) {
        if (attachment.isFilePath) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachment',
              attachment.path!,
              filename: attachment.filename,
            ),
          );
        } else {
          request.files.add(
            http.MultipartFile.fromBytes(
              'attachment',
              attachment.data!,
              filename: attachment.filename,
            ),
          );
        }
      }

      // Add inline images
      for (final embedded in message.embedded) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'inline',
            embedded.path,
            filename: embedded.cid,
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Check response
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw MailTransportException(
          'Mailgun API error: ${error['message'] ?? response.body}',
          error,
        );
      }
    } catch (e, stack) {
      if (e is MailTransportException) rethrow;
      throw MailTransportException(
        'Failed to send email via Mailgun: $e',
        e,
        stack,
      );
    }
  }

  @override
  Future<bool> test() async {
    try {
      // Test by validating domain
      final url = Uri.parse('${_config.endpoint}/v3/domains/${_config.domain}');

      final credentials = base64Encode(utf8.encode('api:${_config.apiKey}'));
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Basic $credentials'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Closes the HTTP client.
  void dispose() {
    _client.close();
  }
}

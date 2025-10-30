import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/mail_config.dart';
import '../contracts/mail_message_interface.dart';
import '../contracts/transport_interface.dart';
import '../exceptions/mail_exception.dart';

/// Postmark transport for sending emails via Postmark service.
///
/// Postmark is a transactional email service focused on delivery speed
/// and reliability. This transport uses Postmark's Send Email API.
///
/// Example configuration:
/// ```dart
/// final config = PostmarkConfig(
///   serverToken: 'your-server-token',
///   messageStream: 'outbound',
/// );
/// final transport = PostmarkTransport(config);
/// ```
///
/// See: https://postmarkapp.com/developer/api/email-api
class PostmarkTransport implements TransportInterface {
  final PostmarkConfig _config;
  final http.Client _client;

  PostmarkTransport(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get name => 'postmark';

  @override
  Future<bool> send(MailMessageInterface message) async {
    try {
      // Validate message
      message.validate();

      // Build request payload
      final payload = await _buildPayload(message);

      // Send request
      final url = Uri.parse('https://api.postmarkapp.com/email');

      final response = await _client.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Postmark-Server-Token': _config.serverToken,
        },
        body: json.encode(payload),
      );

      // Check response
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw MailTransportException(
          'Postmark API error: ${error['Message'] ?? response.body}',
          error,
        );
      }
    } catch (e, stack) {
      if (e is MailTransportException) rethrow;
      throw MailTransportException(
        'Failed to send email via Postmark: $e',
        e,
        stack,
      );
    }
  }

  @override
  Future<bool> test() async {
    try {
      // Test by getting server details
      final url = Uri.parse('https://api.postmarkapp.com/server');

      final response = await _client.get(
        url,
        headers: {
          'Accept': 'application/json',
          'X-Postmark-Server-Token': _config.serverToken,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Builds the Postmark API payload.
  Future<Map<String, dynamic>> _buildPayload(
    MailMessageInterface message,
  ) async {
    final payload = <String, dynamic>{
      'From': message.from?.toString() ?? 'noreply@example.com',
      'To': message.to.map((addr) => addr.toString()).join(', '),
      'Subject': message.subject ?? '',
    };

    // Add CC recipients
    if (message.cc.isNotEmpty) {
      payload['Cc'] = message.cc.map((addr) => addr.toString()).join(', ');
    }

    // Add BCC recipients
    if (message.bcc.isNotEmpty) {
      payload['Bcc'] = message.bcc.map((addr) => addr.toString()).join(', ');
    }

    // Add reply-to
    if (message.replyTo != null) {
      payload['ReplyTo'] = message.replyTo.toString();
    }

    // Add text body
    if (message.textBody != null) {
      payload['TextBody'] = message.textBody;
    }

    // Add HTML body
    if (message.htmlBody != null) {
      payload['HtmlBody'] = message.htmlBody;
    }

    // Add message stream
    if (_config.messageStream != null) {
      payload['MessageStream'] = _config.messageStream;
    }

    // Add custom headers
    if (message.headers.isNotEmpty) {
      final headers = <Map<String, String>>[];
      for (final entry in message.headers.entries) {
        headers.add({'Name': entry.key, 'Value': entry.value});
      }
      payload['Headers'] = headers;
    }

    // Add priority
    if (message.priority != 3) {
      payload['Headers'] ??= [];
      (payload['Headers'] as List).add({
        'Name': 'X-Priority',
        'Value': message.priority.toString(),
      });
    }

    // Add attachments
    if (message.attachments.isNotEmpty) {
      final attachments = <Map<String, dynamic>>[];

      for (final attachment in message.attachments) {
        List<int> data;
        if (attachment.isFilePath) {
          final file = File(attachment.path!);
          data = await file.readAsBytes();
        } else {
          data = attachment.data!;
        }

        attachments.add({
          'Name': attachment.filename,
          'Content': base64Encode(data),
          'ContentType': attachment.mimeType ?? 'application/octet-stream',
        });
      }

      payload['Attachments'] = attachments;
    }

    // Add inline images
    if (message.embedded.isNotEmpty) {
      final inlineImages = <Map<String, dynamic>>[];

      for (final embedded in message.embedded) {
        final file = File(embedded.path);
        final data = await file.readAsBytes();

        inlineImages.add({
          'Name': embedded.cid,
          'Content': base64Encode(data),
          'ContentType': embedded.mimeType ?? 'image/png',
          'ContentID': 'cid:${embedded.cid}',
        });
      }

      // Postmark uses Attachments with ContentID for inline images
      payload['Attachments'] ??= [];
      (payload['Attachments'] as List).addAll(inlineImages);
    }

    return payload;
  }

  /// Closes the HTTP client.
  void dispose() {
    _client.close();
  }
}

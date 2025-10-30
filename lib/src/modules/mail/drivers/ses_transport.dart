import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/mail_config.dart';
import '../contracts/mail_message_interface.dart';
import '../contracts/transport_interface.dart';
import '../exceptions/mail_exception.dart';

/// Amazon SES transport for sending emails via AWS Simple Email Service.
///
/// Amazon SES is a cost-effective email service built on AWS infrastructure.
/// This transport uses the SES v2 API to send emails.
///
/// Example configuration:
/// ```dart
/// final config = SesConfig(
///   accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
///   secretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
///   region: 'us-east-1',
/// );
/// final transport = SesTransport(config);
/// ```
///
/// See: https://docs.aws.amazon.com/ses/latest/APIReference/
class SesTransport implements TransportInterface {
  final SesConfig _config;
  final http.Client _client;

  SesTransport(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get name => 'ses';

  @override
  Future<bool> send(MailMessageInterface message) async {
    try {
      // Validate message
      message.validate();

      // Build email content
      final emailContent = _buildRawEmail(message);

      // Build request payload
      final payload = {
        'Content': {
          'Raw': {
            'Data': base64Encode(utf8.encode(emailContent)),
          },
        },
        if (_config.configurationSet != null)
          'ConfigurationSetName': _config.configurationSet,
      };

      // Send request to SES v2 API
      final url = Uri.parse(
        'https://email.${_config.region}.amazonaws.com/v2/email/outbound-emails',
      );

      final response = await _client.post(
        url,
        headers: _buildHeaders(payload),
        body: json.encode(payload),
      );

      // Check response
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw MailTransportException(
          'SES API error: ${error['message'] ?? response.body}',
          error,
        );
      }
    } catch (e, stack) {
      if (e is MailTransportException) rethrow;
      throw MailTransportException(
        'Failed to send email via SES: $e',
        e,
        stack,
      );
    }
  }

  @override
  Future<bool> test() async {
    try {
      // Test by getting account details
      final url = Uri.parse(
        'https://email.${_config.region}.amazonaws.com/v2/email/account',
      );

      final response = await _client.get(
        url,
        headers: _buildHeaders({}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Builds raw email content in RFC 822 format.
  String _buildRawEmail(MailMessageInterface message) {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln('From: ${message.from}');
    buffer.writeln('To: ${message.to.join(', ')}');

    if (message.cc.isNotEmpty) {
      buffer.writeln('Cc: ${message.cc.join(', ')}');
    }

    if (message.bcc.isNotEmpty) {
      buffer.writeln('Bcc: ${message.bcc.join(', ')}');
    }

    buffer.writeln('Subject: ${message.subject}');
    buffer.writeln('MIME-Version: 1.0');

    if (message.replyTo != null) {
      buffer.writeln('Reply-To: ${message.replyTo}');
    }

    // Custom headers
    for (final entry in message.headers.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }

    // Priority
    if (message.priority != 3) {
      buffer.writeln('X-Priority: ${message.priority}');
    }

    // Content
    if (message.attachments.isEmpty && message.embedded.isEmpty) {
      // Simple message
      if (message.htmlBody != null && message.textBody != null) {
        final boundary = _generateBoundary();
        buffer.writeln(
          'Content-Type: multipart/alternative; boundary="$boundary"',
        );
        buffer.writeln();
        buffer.writeln('--$boundary');
        buffer.writeln('Content-Type: text/plain; charset=UTF-8');
        buffer.writeln();
        buffer.writeln(message.textBody);
        buffer.writeln();
        buffer.writeln('--$boundary');
        buffer.writeln('Content-Type: text/html; charset=UTF-8');
        buffer.writeln();
        buffer.writeln(message.htmlBody);
        buffer.writeln();
        buffer.writeln('--$boundary--');
      } else if (message.htmlBody != null) {
        buffer.writeln('Content-Type: text/html; charset=UTF-8');
        buffer.writeln();
        buffer.writeln(message.htmlBody);
      } else {
        buffer.writeln('Content-Type: text/plain; charset=UTF-8');
        buffer.writeln();
        buffer.writeln(message.textBody);
      }
    } else {
      // Complex message with attachments
      final boundary = _generateBoundary();
      buffer.writeln('Content-Type: multipart/mixed; boundary="$boundary"');
      buffer.writeln();
      buffer.writeln('--$boundary');

      // Body
      if (message.htmlBody != null) {
        buffer.writeln('Content-Type: text/html; charset=UTF-8');
        buffer.writeln();
        buffer.writeln(message.htmlBody);
      } else {
        buffer.writeln('Content-Type: text/plain; charset=UTF-8');
        buffer.writeln();
        buffer.writeln(message.textBody);
      }

      // Note: Full attachment implementation would require reading files
      // For now, this is a simplified version
      buffer.writeln('--$boundary--');
    }

    return buffer.toString();
  }

  /// Builds AWS Signature V4 headers.
  Map<String, String> _buildHeaders(Map<String, dynamic> payload) {
    final now = DateTime.now().toUtc();
    final dateStamp = _formatDateStamp(now);
    final amzDate = _formatAmzDate(now);

    return {
      'Content-Type': 'application/json',
      'X-Amz-Date': amzDate,
      'Authorization': _buildAuthHeader(payload, dateStamp, amzDate),
    };
  }

  /// Builds AWS Signature V4 authorization header.
  String _buildAuthHeader(
    Map<String, dynamic> payload,
    String dateStamp,
    String amzDate,
  ) {
    // This is a simplified version
    // Full AWS Signature V4 implementation would be more complex
    final credential =
        '${_config.accessKeyId}/$dateStamp/${_config.region}/ses/aws4_request';
    return 'AWS4-HMAC-SHA256 Credential=$credential, SignedHeaders=content-type;host;x-amz-date, Signature=placeholder';
  }

  /// Formats date for AWS signature (YYYYMMDD).
  String _formatDateStamp(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// Formats date for AMZ header (YYYYMMDDTHHMMSSZ).
  String _formatAmzDate(DateTime date) {
    return '${_formatDateStamp(date)}T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}Z';
  }

  /// Generates a MIME boundary.
  String _generateBoundary() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '----=_Part_${timestamp}_${timestamp % 100000}';
  }

  /// Closes the HTTP client.
  void dispose() {
    _client.close();
  }
}

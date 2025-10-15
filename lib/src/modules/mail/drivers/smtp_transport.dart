import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/mail_config.dart';
import '../contracts/mail_message_interface.dart';
import '../contracts/transport_interface.dart';
import '../exceptions/mail_exception.dart';

/// SMTP transport for sending emails via SMTP protocol.
///
/// Supports standard SMTP features including:
/// - TLS/SSL encryption
/// - Authentication
/// - Configurable ports and timeouts
///
/// Example configuration:
/// ```dart
/// final config = SmtpConfig(
///   host: 'smtp.gmail.com',
///   port: 587,
///   username: 'user@gmail.com',
///   password: 'app-password',
///   encryption: 'tls',
/// );
/// final transport = SmtpTransport(config);
/// ```
class SmtpTransport implements TransportInterface {
  final SmtpConfig _config;
  SecureSocket? _socket;
  Socket? _plainSocket;
  bool _isConnected = false;
  Stream<List<int>>? _socketStream;

  SmtpTransport(this._config);

  @override
  String get name => 'smtp';

  @override
  Future<bool> send(MailMessageInterface message) async {
    try {
      // Validate message
      message.validate();

      // Connect to SMTP server
      await _connect();

      // Send EHLO/HELO
      await _sendCommand('EHLO ${_config.host}', expectedCode: 250);

      // Authenticate if credentials provided
      if (_config.username != null && _config.password != null) {
        await _authenticate();
      }

      // Send MAIL FROM
      final fromEmail = message.from?.email ?? 'noreply@localhost';
      await _sendCommand('MAIL FROM:<$fromEmail>', expectedCode: 250);

      // Send RCPT TO for all recipients
      await _sendRecipients(message);

      // Send DATA
      await _sendCommand('DATA', expectedCode: 354);

      // Send message content
      await _sendMessageContent(message);

      // End DATA
      await _sendCommand('.', expectedCode: 250);

      // Quit
      await _sendCommand('QUIT', expectedCode: 221);

      await _disconnect();
      return true;
    } catch (e, stack) {
      await _disconnect();
      throw MailTransportException(
        'Failed to send email via SMTP: $e',
        e,
        stack,
      );
    }
  }

  @override
  Future<bool> test() async {
    try {
      await _connect();
      await _sendCommand('EHLO ${_config.host}', expectedCode: 250);
      await _sendCommand('QUIT', expectedCode: 221);
      await _disconnect();
      return true;
    } catch (e) {
      await _disconnect();
      return false;
    }
  }

  /// Connects to the SMTP server.
  Future<void> _connect() async {
    if (_isConnected) return;

    try {
      final timeout = Duration(seconds: _config.timeout);

      if (_config.encryption == 'ssl') {
        // Direct SSL connection
        try {
          _socket = await SecureSocket.connect(
            _config.host,
            _config.port,
            timeout: timeout,
          );
          _socketStream = _socket!.asBroadcastStream();
          _isConnected = true;
          await _readResponse(); // Read server greeting
        } on SocketException catch (e) {
          throw MailTransportException(
            'Failed to connect to SMTP server ${_config.host}:${_config.port} using SSL. '
            'Please check:\n'
            '1. SMTP host and port are correct\n'
            '2. Firewall allows outbound connections on port ${_config.port}\n'
            '3. SMTP server supports SSL on this port\n'
            'Error: ${e.message}',
          );
        }
      } else {
        // Plain connection (will upgrade to TLS if needed)
        try {
          _plainSocket = await Socket.connect(
            _config.host,
            _config.port,
            timeout: timeout,
          );
          _socketStream = _plainSocket!.asBroadcastStream();
          _isConnected = true;
          await _readResponse(); // Read server greeting

          if (_config.encryption == 'tls') {
            // Upgrade to TLS
            await _sendCommand('STARTTLS', expectedCode: 220);
            _socket = await SecureSocket.secure(
              _plainSocket!,
              host: _config.host,
            );
            _socketStream = _socket!.asBroadcastStream();
            _plainSocket = null;
          }
        } on SocketException catch (e) {
          throw MailTransportException(
            'Failed to connect to SMTP server ${_config.host}:${_config.port}. '
            'Please check:\n'
            '1. SMTP host and port are correct\n'
            '2. Firewall allows outbound connections on port ${_config.port}\n'
            '3. Network connectivity is working\n'
            'Error: ${e.message}',
          );
        } on TimeoutException {
          throw MailTransportException(
            'Connection to SMTP server ${_config.host}:${_config.port} timed out after ${_config.timeout} seconds. '
            'Please check:\n'
            '1. SMTP server is running and accessible\n'
            '2. Firewall is not blocking the connection\n'
            '3. Network latency is acceptable\n'
            'Consider increasing the timeout in your configuration.',
          );
        }
      }
    } catch (e) {
      if (e is MailTransportException) rethrow;
      throw MailTransportException('Failed to connect to SMTP server: $e');
    }
  }

  /// Disconnects from the SMTP server.
  Future<void> _disconnect() async {
    try {
      await _socket?.close();
      await _plainSocket?.close();
    } catch (_) {
      // Ignore disconnect errors
    } finally {
      _socket = null;
      _plainSocket = null;
      _socketStream = null;
      _isConnected = false;
    }
  }

  /// Authenticates with the SMTP server using LOGIN method.
  Future<void> _authenticate() async {
    await _sendCommand('AUTH LOGIN', expectedCode: 334);

    // Send username (base64 encoded)
    final usernameEncoded = base64Encode(utf8.encode(_config.username!));
    await _sendCommand(usernameEncoded, expectedCode: 334);

    // Send password (base64 encoded)
    final passwordEncoded = base64Encode(utf8.encode(_config.password!));
    await _sendCommand(passwordEncoded, expectedCode: 235);
  }

  /// Sends RCPT TO commands for all recipients.
  Future<void> _sendRecipients(MailMessageInterface message) async {
    // TO recipients
    for (final recipient in message.to) {
      await _sendCommand('RCPT TO:<${recipient.email}>', expectedCode: 250);
    }

    // CC recipients
    for (final recipient in message.cc) {
      await _sendCommand('RCPT TO:<${recipient.email}>', expectedCode: 250);
    }

    // BCC recipients
    for (final recipient in message.bcc) {
      await _sendCommand('RCPT TO:<${recipient.email}>', expectedCode: 250);
    }
  }

  /// Sends the email message content.
  Future<void> _sendMessageContent(MailMessageInterface message) async {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln('From: ${message.from}');
    buffer.writeln('To: ${message.to.join(', ')}');

    if (message.cc.isNotEmpty) {
      buffer.writeln('Cc: ${message.cc.join(', ')}');
    }

    buffer.writeln('Subject: ${message.subject}');
    buffer.writeln('Date: ${_formatDate(DateTime.now())}');
    buffer.writeln('Message-ID: <${_generateMessageId()}>');
    buffer.writeln('MIME-Version: 1.0');

    // Custom headers
    for (final entry in message.headers.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }

    // Priority header
    if (message.priority != 3) {
      buffer.writeln('X-Priority: ${message.priority}');
    }

    // Reply-To
    if (message.replyTo != null) {
      buffer.writeln('Reply-To: ${message.replyTo}');
    }

    // Content
    if (message.attachments.isEmpty && message.embedded.isEmpty) {
      // Simple message (no attachments)
      if (message.htmlBody != null && message.textBody != null) {
        // Multipart alternative
        final boundary = _generateBoundary();
        buffer.writeln('Content-Type: multipart/alternative; boundary="$boundary"');
        buffer.writeln();
        buffer.writeln('--$boundary');
        buffer.writeln('Content-Type: text/plain; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: quoted-printable');
        buffer.writeln();
        buffer.writeln(_encodeQuotedPrintable(message.textBody!));
        buffer.writeln();
        buffer.writeln('--$boundary');
        buffer.writeln('Content-Type: text/html; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: quoted-printable');
        buffer.writeln();
        buffer.writeln(_encodeQuotedPrintable(message.htmlBody!));
        buffer.writeln();
        buffer.writeln('--$boundary--');
      } else if (message.htmlBody != null) {
        // HTML only
        buffer.writeln('Content-Type: text/html; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: quoted-printable');
        buffer.writeln();
        buffer.writeln(_encodeQuotedPrintable(message.htmlBody!));
      } else {
        // Plain text only
        buffer.writeln('Content-Type: text/plain; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: quoted-printable');
        buffer.writeln();
        buffer.writeln(_encodeQuotedPrintable(message.textBody!));
      }
    } else {
      // Complex message with attachments
      final boundary = _generateBoundary();
      buffer.writeln('Content-Type: multipart/mixed; boundary="$boundary"');
      buffer.writeln();

      // Body part
      buffer.writeln('--$boundary');
      if (message.htmlBody != null && message.textBody != null) {
        final altBoundary = _generateBoundary();
        buffer.writeln('Content-Type: multipart/alternative; boundary="$altBoundary"');
        buffer.writeln();
        buffer.writeln('--$altBoundary');
        buffer.writeln('Content-Type: text/plain; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: quoted-printable');
        buffer.writeln();
        buffer.writeln(_encodeQuotedPrintable(message.textBody!));
        buffer.writeln();
        buffer.writeln('--$altBoundary');
        buffer.writeln('Content-Type: text/html; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: quoted-printable');
        buffer.writeln();
        buffer.writeln(_encodeQuotedPrintable(message.htmlBody!));
        buffer.writeln();
        buffer.writeln('--$altBoundary--');
      } else if (message.htmlBody != null) {
        buffer.writeln('Content-Type: text/html; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: quoted-printable');
        buffer.writeln();
        buffer.writeln(_encodeQuotedPrintable(message.htmlBody!));
      } else {
        buffer.writeln('Content-Type: text/plain; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: quoted-printable');
        buffer.writeln();
        buffer.writeln(_encodeQuotedPrintable(message.textBody!));
      }

      // Attachments
      for (final attachment in message.attachments) {
        buffer.writeln();
        buffer.writeln('--$boundary');
        await _writeAttachment(buffer, attachment);
      }

      // Embedded files
      for (final embedded in message.embedded) {
        buffer.writeln();
        buffer.writeln('--$boundary');
        await _writeEmbedded(buffer, embedded);
      }

      buffer.writeln();
      buffer.writeln('--$boundary--');
    }

    // Write to socket
    await _write(buffer.toString());
  }

  /// Writes an attachment to the message.
  Future<void> _writeAttachment(
    StringBuffer buffer,
    MailAttachment attachment,
  ) async {
    final mimeType = attachment.mimeType ?? 'application/octet-stream';
    buffer.writeln('Content-Type: $mimeType; name="${attachment.filename}"');
    buffer.writeln('Content-Transfer-Encoding: base64');
    buffer.writeln('Content-Disposition: attachment; filename="${attachment.filename}"');
    buffer.writeln();

    List<int> data;
    if (attachment.isFilePath) {
      final file = File(attachment.path!);
      data = await file.readAsBytes();
    } else {
      data = attachment.data!;
    }

    buffer.writeln(_encodeBase64Lines(data));
  }

  /// Writes an embedded file to the message.
  Future<void> _writeEmbedded(
    StringBuffer buffer,
    MailEmbedded embedded,
  ) async {
    final mimeType = embedded.mimeType ?? 'application/octet-stream';
    buffer.writeln('Content-Type: $mimeType');
    buffer.writeln('Content-Transfer-Encoding: base64');
    buffer.writeln('Content-ID: <${embedded.cid}>');
    buffer.writeln('Content-Disposition: inline');
    buffer.writeln();

    // Embedded files are always file paths
    final file = File(embedded.path);
    final data = await file.readAsBytes();

    buffer.writeln(_encodeBase64Lines(data));
  }

  /// Sends a command to the SMTP server.
  Future<void> _sendCommand(String command, {int? expectedCode}) async {
    await _write('$command\r\n');
    final response = await _readResponse();

    if (expectedCode != null) {
      final code = _parseResponseCode(response);
      if (code != expectedCode) {
        throw MailTransportException(
          'SMTP error: Expected $expectedCode, got $code - $response',
        );
      }
    }
  }

  /// Writes data to the socket.
  Future<void> _write(String data) async {
    final socket = _socket ?? _plainSocket;
    if (socket == null) {
      throw MailTransportException('Not connected to SMTP server');
    }

    socket.write(data);
    await socket.flush();
  }

  /// Reads a response from the SMTP server.
  Future<String> _readResponse() async {
    if (_socketStream == null) {
      throw MailTransportException('Not connected to SMTP server');
    }

    final response = StringBuffer();
    await for (final data in _socketStream!) {
      final text = utf8.decode(data);
      response.write(text);

      // Check if this is the last line of the response
      if (text.contains('\n')) {
        final lines = text.split('\n');
        final lastLine = lines[lines.length - 2]; // -2 because last is empty
        if (lastLine.length >= 4 && lastLine[3] == ' ') {
          break;
        }
      }
    }

    return response.toString();
  }

  /// Parses the response code from an SMTP response.
  int _parseResponseCode(String response) {
    if (response.length < 3) {
      throw MailTransportException('Invalid SMTP response: $response');
    }
    return int.parse(response.substring(0, 3));
  }

  /// Formats a date for email headers (RFC 2822).
  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final offset = date.timeZoneOffset;
    final offsetSign = offset.isNegative ? '-' : '+';
    final offsetHours = offset.abs().inHours.toString().padLeft(2, '0');
    final offsetMinutes = (offset.abs().inMinutes % 60).toString().padLeft(2, '0');

    return '$weekday, ${date.day} $month ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')} '
        '$offsetSign$offsetHours$offsetMinutes';
  }

  /// Generates a unique message ID.
  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 100000;
    return '$timestamp.$random@${_config.host}';
  }

  /// Generates a MIME boundary.
  String _generateBoundary() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 100000;
    return '----=_Part_${timestamp}_$random';
  }

  /// Encodes text using quoted-printable encoding.
  String _encodeQuotedPrintable(String text) {
    final buffer = StringBuffer();
    final bytes = utf8.encode(text);
    var lineLength = 0;

    for (var byte in bytes) {
      if (byte == 10) {
        // Newline
        buffer.write('\r\n');
        lineLength = 0;
      } else if (byte >= 33 && byte <= 126 && byte != 61) {
        // Printable ASCII (except =)
        buffer.writeCharCode(byte);
        lineLength++;
      } else {
        // Encode as =XX
        buffer.write('=${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
        lineLength += 3;
      }

      // Soft line break at 76 characters
      if (lineLength >= 73) {
        buffer.write('=\r\n');
        lineLength = 0;
      }
    }

    return buffer.toString();
  }

  /// Encodes data as base64 with line breaks.
  String _encodeBase64Lines(List<int> data) {
    final encoded = base64Encode(data);
    final buffer = StringBuffer();

    // Split into 76-character lines
    for (var i = 0; i < encoded.length; i += 76) {
      final end = (i + 76 < encoded.length) ? i + 76 : encoded.length;
      buffer.writeln(encoded.substring(i, end));
    }

    return buffer.toString();
  }
}

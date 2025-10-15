import 'dart:io';

import '../../../contracts/queue/queue_job.dart';
import '../../../core/queue/queue_manager.dart';
import '../../../core/view/renderer.dart';
import '../contracts/mailable.dart';
import '../contracts/mail_message_interface.dart';
import '../contracts/mailer_interface.dart';
import '../contracts/transport_interface.dart';
import '../exceptions/mail_exception.dart';
import 'mail_message.dart';

/// Default implementation of MailerInterface.
///
/// Provides a fluent API for building and sending emails.
class Mailer implements MailerInterface {
  final TransportInterface _transport;
  final QueueManager? _queueManager;
  final MailAddress? _defaultFrom;
  final MailMessage _message = MailMessage();

  Mailer(
    this._transport, {
    QueueManager? queueManager,
    MailAddress? defaultFrom,
  })  : _queueManager = queueManager,
        _defaultFrom = defaultFrom {
    // Set default from address if provided
    if (_defaultFrom != null) {
      _message.setFrom(_defaultFrom!.email, _defaultFrom!.name);
    }
  }

  @override
  MailerInterface to(dynamic addresses) {
    _addAddresses(addresses, _message.addTo);
    return this;
  }

  @override
  MailerInterface cc(dynamic addresses) {
    _addAddresses(addresses, _message.addCc);
    return this;
  }

  @override
  MailerInterface bcc(dynamic addresses) {
    _addAddresses(addresses, _message.addBcc);
    return this;
  }

  @override
  MailerInterface replyTo(String address, [String? name]) {
    _message.setReplyTo(address, name);
    return this;
  }

  @override
  MailerInterface subject(String subject) {
    _message.setSubject(subject);
    return this;
  }

  @override
  MailerInterface from(String address, [String? name]) {
    _message.setFrom(address, name);
    return this;
  }

  @override
  MailerInterface text(String content) {
    _message.setTextBody(content);
    return this;
  }

  @override
  MailerInterface html(String content) {
    _message.setHtmlBody(content);
    return this;
  }

  @override
  Future<MailerInterface> view(
    String viewName, [
    Map<String, dynamic>? data,
  ]) async {
    final renderer = ViewRenderer.instance;
    final htmlContent = await renderer.render(
      viewName,
      context: data ?? {},
    );
    _message.setHtmlBody(htmlContent);

    // Also set text body as stripped HTML (basic implementation)
    final textContent = _stripHtmlTags(htmlContent);
    _message.setTextBody(textContent);

    return this;
  }

  @override
  MailerInterface attach(String path, {String? name, String? mimeType}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw MailException('Attachment file not found: $path');
    }

    _message.addAttachment(MailAttachment(
      path: path,
      filename: name ?? file.uri.pathSegments.last,
      mimeType: mimeType,
    ),);
    return this;
  }

  @override
  MailerInterface attachData(
    List<int> data,
    String name, {
    String? mimeType,
  }) {
    _message.addAttachment(MailAttachment(
      data: data,
      filename: name,
      mimeType: mimeType ?? 'application/octet-stream',
    ),);
    return this;
  }

  @override
  MailerInterface embed(String path, String cid) {
    final file = File(path);
    if (!file.existsSync()) {
      throw MailException('Embed file not found: $path');
    }

    _message.addEmbedded(MailEmbedded(
      path: path,
      cid: cid,
    ),);
    return this;
  }

  @override
  MailerInterface header(String name, String value) {
    _message.setHeader(name, value);
    return this;
  }

  @override
  MailerInterface priority(int priority) {
    _message.setPriority(priority);
    return this;
  }

  @override
  Future<bool> send() async {
    try {
      _message.validate();
      return await _transport.send(_message);
    } catch (e, stack) {
      throw MailException('Failed to send email', e, stack);
    }
  }

  @override
  Future<void> queue([Duration? delay]) async {
    if (_queueManager == null) {
      throw MailException('Queue manager not configured');
    }

    _message.validate();

    // Create a queue job for this email
    final job = _MailJob(_message.copy(), _transport);

    await _queueManager!.dispatch(job, delay: delay);
  }

  @override
  Future<bool> sendMailable(Mailable mailable) async {
    try {
      await mailable.beforeSend();

      // Build the mail using the mailable
      await mailable.build(this);

      // Send the email
      final result = await send();

      if (result) {
        await mailable.afterSend();
      }

      return result;
    } catch (e, stack) {
      await mailable.onError(e, stack);
      rethrow;
    }
  }

  @override
  Future<void> queueMailable(Mailable mailable, [Duration? delay]) async {
    if (_queueManager == null) {
      throw MailException('Queue manager not configured');
    }

    // Build the mail using the mailable
    await mailable.build(this);

    // Validate before queuing
    _message.validate();

    // Create a queue job for this mailable
    final job = _MailableJob(mailable, _message.copy(), _transport);

    await _queueManager!.dispatch(job, delay: delay);
  }

  @override
  MailMessageInterface message() {
    return MailMessage();
  }

  @override
  String get driverName => _transport.name;

  /// Helper to add addresses from various formats.
  void _addAddresses(
    dynamic addresses,
    void Function(String email, String? name) addFunction,
  ) {
    if (addresses is String) {
      addFunction(addresses, null);
    } else if (addresses is Map<String, dynamic>) {
      final email = addresses['email'] as String?;
      final name = addresses['name'] as String?;
      if (email != null) {
        addFunction(email, name);
      }
    } else if (addresses is List) {
      for (final address in addresses) {
        _addAddresses(address, addFunction);
      }
    } else {
      throw MailException('Invalid address format: ${addresses.runtimeType}');
    }
  }

  /// Basic HTML tag stripping for text fallback.
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>',
            multiLine: true, caseSensitive: false,), '',)
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>',
            multiLine: true, caseSensitive: false,), '',)
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Queue job for sending emails.
class _MailJob extends QueueJob {
  final MailMessage message;
  final TransportInterface transport;

  _MailJob(this.message, this.transport);

  @override
  Future<void> handle() async {
    await transport.send(message);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'mail',
        'to': message.to.map((a) => {'email': a.email, 'name': a.name}).toList(),
        'subject': message.subject,
      };

  @override
  String get displayName => 'SendEmail(${message.subject})';
}

/// Queue job for sending mailables.
class _MailableJob extends QueueJob {
  final Mailable mailable;
  final MailMessage message;
  final TransportInterface transport;

  _MailableJob(this.mailable, this.message, this.transport);

  @override
  Future<void> handle() async {
    try {
      await mailable.beforeSend();
      await transport.send(message);
      await mailable.afterSend();
    } catch (e, stack) {
      await mailable.onError(e, stack);
      rethrow;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'mailable',
        'mailable': mailable.displayName,
        'subject': message.subject,
      };

  @override
  String get displayName => 'SendMailable(${mailable.displayName})';
}

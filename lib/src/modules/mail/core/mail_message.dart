import '../contracts/mail_message_interface.dart';
import '../exceptions/mail_exception.dart';

/// Implementation of MailMessageInterface.
///
/// Represents a complete email message with all its parts.
class MailMessage implements MailMessageInterface {
  final List<MailAddress> _to = [];
  final List<MailAddress> _cc = [];
  final List<MailAddress> _bcc = [];
  final List<MailAttachment> _attachments = [];
  final List<MailEmbedded> _embedded = [];
  final Map<String, String> _headers = {};

  MailAddress? _from;
  MailAddress? _replyTo;
  String? _subject;
  String? _textBody;
  String? _htmlBody;
  int _priority = 3; // Normal priority

  @override
  List<MailAddress> get to => List.unmodifiable(_to);

  @override
  List<MailAddress> get cc => List.unmodifiable(_cc);

  @override
  List<MailAddress> get bcc => List.unmodifiable(_bcc);

  @override
  MailAddress? get from => _from;

  @override
  MailAddress? get replyTo => _replyTo;

  @override
  String? get subject => _subject;

  @override
  String? get textBody => _textBody;

  @override
  String? get htmlBody => _htmlBody;

  @override
  List<MailAttachment> get attachments => List.unmodifiable(_attachments);

  @override
  List<MailEmbedded> get embedded => List.unmodifiable(_embedded);

  @override
  Map<String, String> get headers => Map.unmodifiable(_headers);

  @override
  int get priority => _priority;

  @override
  void addTo(String email, [String? name]) {
    _to.add(MailAddress(email, name));
  }

  @override
  void addCc(String email, [String? name]) {
    _cc.add(MailAddress(email, name));
  }

  @override
  void addBcc(String email, [String? name]) {
    _bcc.add(MailAddress(email, name));
  }

  @override
  void setFrom(String email, [String? name]) {
    _from = MailAddress(email, name);
  }

  @override
  void setReplyTo(String email, [String? name]) {
    _replyTo = MailAddress(email, name);
  }

  @override
  void setSubject(String subject) {
    _subject = subject;
  }

  @override
  void setTextBody(String content) {
    _textBody = content;
  }

  @override
  void setHtmlBody(String content) {
    _htmlBody = content;
  }

  @override
  void addAttachment(MailAttachment attachment) {
    _attachments.add(attachment);
  }

  @override
  void addEmbedded(MailEmbedded embedded) {
    _embedded.add(embedded);
  }

  @override
  void setHeader(String name, String value) {
    _headers[name] = value;
  }

  @override
  void setPriority(int priority) {
    if (priority < 1 || priority > 5) {
      throw MailException('Priority must be between 1 and 5');
    }
    _priority = priority;
  }

  @override
  void validate() {
    // Must have at least one recipient
    if (_to.isEmpty && _cc.isEmpty && _bcc.isEmpty) {
      throw MailException('Email must have at least one recipient');
    }

    // Must have a subject
    if (_subject == null || _subject!.trim().isEmpty) {
      throw MailException('Email must have a subject');
    }

    // Must have content (text or HTML)
    if ((_textBody == null || _textBody!.trim().isEmpty) &&
        (_htmlBody == null || _htmlBody!.trim().isEmpty)) {
      throw MailException('Email must have content (text or HTML body)');
    }

    // Validate from address if set
    if (_from != null && !_isValidEmail(_from!.email)) {
      throw MailException('Invalid from email address: ${_from!.email}');
    }

    // Validate all recipient addresses
    for (final address in [..._to, ..._cc, ..._bcc]) {
      if (!_isValidEmail(address.email)) {
        throw MailException('Invalid email address: ${address.email}');
      }
    }
  }

  /// Basic email validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Creates a copy of this message.
  MailMessage copy() {
    final message = MailMessage();

    for (final address in _to) {
      message.addTo(address.email, address.name);
    }
    for (final address in _cc) {
      message.addCc(address.email, address.name);
    }
    for (final address in _bcc) {
      message.addBcc(address.email, address.name);
    }

    if (_from != null) {
      message.setFrom(_from!.email, _from!.name);
    }
    if (_replyTo != null) {
      message.setReplyTo(_replyTo!.email, _replyTo!.name);
    }

    if (_subject != null) message.setSubject(_subject!);
    if (_textBody != null) message.setTextBody(_textBody!);
    if (_htmlBody != null) message.setHtmlBody(_htmlBody!);

    for (final attachment in _attachments) {
      message.addAttachment(attachment);
    }
    for (final embed in _embedded) {
      message.addEmbedded(embed);
    }

    for (final entry in _headers.entries) {
      message.setHeader(entry.key, entry.value);
    }

    message.setPriority(_priority);

    return message;
  }
}

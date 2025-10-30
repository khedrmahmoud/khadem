/// Represents an email address with optional name.
class MailAddress {
  final String email;
  final String? name;

  const MailAddress(this.email, [this.name]);

  @override
  String toString() => name != null ? '$name <$email>' : email;

  @override
  bool operator ==(Object other) =>
      other is MailAddress && other.email == email && other.name == name;

  @override
  int get hashCode => Object.hash(email, name);
}

/// Represents a file attachment.
class MailAttachment {
  final String? path;
  final List<int>? data;
  final String filename;
  final String? mimeType;

  const MailAttachment({
    required this.filename,
    this.path,
    this.data,
    this.mimeType,
  }) : assert(
          path != null || data != null,
          'Either path or data must be provided',
        );

  bool get isFilePath => path != null;
  bool get isRawData => data != null;
}

/// Represents an embedded file (inline attachment).
class MailEmbedded {
  final String path;
  final String cid;
  final String? mimeType;

  const MailEmbedded({
    required this.path,
    required this.cid,
    this.mimeType,
  });
}

/// Represents an email message that can be sent.
///
/// This interface defines the structure of an email message
/// including recipients, content, attachments, and metadata.
abstract interface class MailMessageInterface {
  /// List of recipient addresses.
  List<MailAddress> get to;

  /// List of CC addresses.
  List<MailAddress> get cc;

  /// List of BCC addresses.
  List<MailAddress> get bcc;

  /// The sender address.
  MailAddress? get from;

  /// The reply-to address.
  MailAddress? get replyTo;

  /// The email subject.
  String? get subject;

  /// The plain text body.
  String? get textBody;

  /// The HTML body.
  String? get htmlBody;

  /// List of file attachments.
  List<MailAttachment> get attachments;

  /// List of embedded images/files.
  List<MailEmbedded> get embedded;

  /// Custom headers.
  Map<String, String> get headers;

  /// Email priority (1-5, where 1 is highest).
  int get priority;

  /// Adds a recipient.
  void addTo(String email, [String? name]);

  /// Adds a CC recipient.
  void addCc(String email, [String? name]);

  /// Adds a BCC recipient.
  void addBcc(String email, [String? name]);

  /// Sets the sender.
  void setFrom(String email, [String? name]);

  /// Sets the reply-to address.
  void setReplyTo(String email, [String? name]);

  /// Sets the subject.
  void setSubject(String subject);

  /// Sets the text body.
  void setTextBody(String content);

  /// Sets the HTML body.
  void setHtmlBody(String content);

  /// Adds an attachment.
  void addAttachment(MailAttachment attachment);

  /// Adds an embedded file.
  void addEmbedded(MailEmbedded embedded);

  /// Sets a custom header.
  void setHeader(String name, String value);

  /// Sets the priority.
  void setPriority(int priority);

  /// Validates the message before sending.
  ///
  /// Throws an exception if the message is invalid.
  void validate();
}

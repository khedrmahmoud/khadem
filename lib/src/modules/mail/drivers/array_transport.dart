import '../contracts/mail_message_interface.dart';
import '../contracts/transport_interface.dart';

/// Array mail transport for testing.
///
/// Stores sent emails in memory for assertions in tests.
/// Never actually sends emails.
class ArrayTransport implements TransportInterface {
  final List<MailMessageInterface> _sent = [];

  @override
  Future<bool> send(MailMessageInterface message) async {
    _sent.add(message);
    return true;
  }

  @override
  String get name => 'array';

  @override
  Future<bool> test() async => true;

  /// Gets all sent messages.
  List<MailMessageInterface> get sent => List.unmodifiable(_sent);

  /// Clears all sent messages.
  void clear() {
    _sent.clear();
  }

  /// Gets the count of sent messages.
  int get count => _sent.length;

  /// Checks if any messages were sent.
  bool get hasSent => _sent.isNotEmpty;

  /// Checks if a message matching the predicate was sent.
  bool wasSent(bool Function(MailMessageInterface) predicate) {
    return _sent.any(predicate);
  }

  /// Gets all messages matching the predicate.
  List<MailMessageInterface> findSent(
    bool Function(MailMessageInterface) predicate,
  ) {
    return _sent.where(predicate).toList();
  }

  /// Asserts that a message was sent to the given address.
  bool wasSentTo(String email) {
    return _sent.any((msg) => msg.to.any((addr) => addr.email == email));
  }

  /// Asserts that a message with the given subject was sent.
  bool wasSentWithSubject(String subject) {
    return _sent.any((msg) => msg.subject == subject);
  }

  /// Gets the last sent message, or null if none sent.
  MailMessageInterface? get lastSent => _sent.isEmpty ? null : _sent.last;

  /// Gets the first sent message, or null if none sent.
  MailMessageInterface? get firstSent => _sent.isEmpty ? null : _sent.first;
}

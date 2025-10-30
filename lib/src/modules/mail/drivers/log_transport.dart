import '../../../core/logging/logger.dart';
import '../contracts/mail_message_interface.dart';
import '../contracts/transport_interface.dart';

/// Log mail transport for development.
///
/// Instead of actually sending emails, logs them to the application log.
/// Useful for testing and development.
class LogTransport implements TransportInterface {
  final Logger _logger;
  final bool _verbose;

  LogTransport(this._logger, {bool verbose = true}) : _verbose = verbose;

  @override
  Future<bool> send(MailMessageInterface message) async {
    try {
      _logger.info('📧 Email logged (not sent)');
      _logger.info('  From: ${message.from}');
      _logger.info('  To: ${message.to.join(', ')}');

      if (message.cc.isNotEmpty) {
        _logger.info('  CC: ${message.cc.join(', ')}');
      }

      if (message.bcc.isNotEmpty) {
        _logger.info('  BCC: ${message.bcc.join(', ')}');
      }

      _logger.info('  Subject: ${message.subject}');

      if (_verbose) {
        if (message.textBody != null) {
          _logger.info('  Text Body:');
          _logger.info('    ${message.textBody}');
        }

        if (message.htmlBody != null) {
          _logger.info('  HTML Body:');
          _logger.info('    ${message.htmlBody?.substring(0, 100)}...');
        }

        if (message.attachments.isNotEmpty) {
          _logger.info('  Attachments: ${message.attachments.length}');
          for (final attachment in message.attachments) {
            _logger.info('    - ${attachment.filename}');
          }
        }

        if (message.embedded.isNotEmpty) {
          _logger.info('  Embedded: ${message.embedded.length}');
          for (final embed in message.embedded) {
            _logger.info('    - ${embed.cid}');
          }
        }
      }

      return true;
    } catch (e, stack) {
      _logger.error('Failed to log email: $e\n$stack');
      return false;
    }
  }

  @override
  String get name => 'log';

  @override
  Future<bool> test() async {
    _logger.info('Log transport is always available');
    return true;
  }
}

import 'package:khadem/khadem.dart' show Khadem;

import '../../session/session_manager.dart';
import '../context/request_context.dart';
import 'response.dart';

/// Extensions for Response class to handle session and request context operations.
extension ResponseExtensions on Response {
  /// Store a value in the session
  /// [key] The session attribute key
  /// [value] The value to store
  Response sessionPut(String key, dynamic value) {
    try {
      RequestContext.request.session.set(key, value);
    } catch (_) {}
    return this;
  }

  /// Flash input data to session for next request
  /// [inputData] Map of old input values
  Response flashInput(Map<String, dynamic> inputData) {
    try {
      final req = RequestContext.request;
      final sessionId = req.attribute<String>('session_id');
      if (sessionId != null) {
        final manager = Khadem.container.resolve<SessionManager>();
        manager.flashOldInput(sessionId, inputData);
      }
    } catch (_) {}
    return this;
  }
}

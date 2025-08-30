import 'dart:async';

import '../context/request_context.dart';
import '../context/response_context.dart';
import '../context/server_context.dart';
import '../request/request.dart';
import '../response/response.dart';
import 'server_router.dart';

/// Handles server context and zone management.
class ServerContextManager {
  final ServerRouter _router;

  ServerContextManager(this._router);

  /// Creates a zone with proper context for request processing.
  Zone createRequestZone(Request req, Response res) {
    return Zone.current.fork(
      zoneValues: {
        RequestContext.zoneKey: req,
        ResponseContext.zoneKey: res,
        ServerContext.zoneKey: ServerContext(
          request: req,
          response: res,
          match: _router.router.match,
        ),
      },
    );
  }
}

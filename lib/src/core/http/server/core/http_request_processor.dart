import 'dart:async';

import '../../../routing/router.dart';
import '../../context/server_context.dart';
import '../../middleware/middleware_pipeline.dart';
import '../../request/request.dart';
import '../../response/response.dart';
import 'static_handler.dart';

/// Handles routing, middleware, and invoking the route handler.
class HttpRequestProcessor {
  final Router router;
  final MiddlewarePipeline globalMiddleware;
  final ServerStaticHandler? staticHandler;

  HttpRequestProcessor({
    required this.router,
    required this.globalMiddleware,
    this.staticHandler,
  });

  Future<void> handle(Request req, Response res) async {
    try {
      final match = router.match(req.method, req.path);

      if (match != null && ServerContext.hasContext) {
        ServerContext.current.setMatch(match);
      }

      if (match == null) {
        if (staticHandler != null && await staticHandler!.tryServe(req, res)) {
          return;
        }
        res.status(404).send('Not Found');
        return;
      }

      // Set route parameters
      match.params.forEach((key, value) {
        req.setParam(key, value);
      });

      // Execute route-specific middleware and then the handler
      // We use the optimized static execute method to avoid allocations
      await MiddlewarePipeline.execute(
        match.middleware,
        req,
        res,
        match.handler,
      );
    } catch (e) {
      // Ensure unhandled exceptions are caught and logged
      // This is a safety net in case the global error handler misses something
      if (!res.sent) {
        res.status(500).sendJson({
          'error': 'Internal Server Error',
          'message': e.toString(),
        });
      }
      // Rethrow to let the global error handler log it
      rethrow;
    }
  }
}

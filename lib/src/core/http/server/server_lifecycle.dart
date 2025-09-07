import 'dart:async';
import 'dart:io';

import 'package:khadem/khadem_dart.dart';


/// Handles server lifecycle operations (start, reload, etc.).
class ServerLifecycle {
  final ServerRouter _router;
  final ServerMiddleware _middleware;
  final ServerStatic _static;
  void Function()? _initializer;

  ServerLifecycle(this._router, this._middleware, this._static);

  /// Sets the initializer function for hot reload support.
  void setInitializer(void Function() initializer) {
    _initializer = initializer;
  }

  /// Reloads routes and middleware using the stored initializer.
  Future<void> reload() async {
    if (_initializer != null) {
      // Reset router, middleware, and static handler
      _router.clear();
      _middleware.clear();
      _static.clear();

      // Re-run initializer to reload routes and middleware
      _initializer!();
      Khadem.logger.info('Routes, middleware, and static files reloaded');
    }
  }

  /// Starts the HTTP server on the specified port.
  ///
  /// Automatically applies global middleware and routes.
  Future<void> start({int port = 8080}) async {
    final handler = HttpRequestProcessor(
      router: _router.router,
      globalMiddleware: _middleware.pipeline,
      staticHandler: _static.staticHandler,
    );

    final server =
        await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    Khadem.logger.info('🟢 HTTP Server started on http://localhost:$port');
    await for (final raw in server) {
      final req = Request(raw);
      final res = Response(raw);

      Zone.current.fork(
        zoneValues: {
          RequestContext.zoneKey: req,
          ResponseContext.zoneKey: res,
          ServerContext.zoneKey: ServerContext(
            request: req,
            response: res,
            match: _router.router.match,
          ),
        },
      ).run(() async {
        try {
          await _middleware.pipeline.process(req, res);
          if (!res.sent) await handler.handle(req, res);
        } catch (e, stackTrace) {
          ExceptionHandler.handle(res, e, stackTrace);
        }
      });
    }
  }
}

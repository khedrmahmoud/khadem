import 'dart:async';
import 'dart:io';

import 'package:khadem/khadem.dart';

class ServerLifecycle {
  final ServerRouter _router;
  final ServerMiddleware _middleware;
  final ServerStatic _static;

  // Configuration
  bool autoCompress = true;
  Duration idleTimeout = const Duration(seconds: 120);

  ServerLifecycle(this._router, this._middleware, this._static);

  Future<void> reload() async {
    // Fallback to manual reload
    _router.clear();
    _middleware.clear();
    _static.clear();
  }

  Future<void> start({int port = 8080, String? host}) async {
    final handler = HttpRequestProcessor(
      router: _router.router,
      globalMiddleware: _middleware.pipeline,
      staticHandler: _static.staticHandler,
    );

    final server = await HttpServer.bind(
      host != null ? InternetAddress(host) : InternetAddress.anyIPv4,
      port,
      shared: true,
    );

    // Enable compression and set idle timeout
    server.autoCompress = autoCompress;
    server.idleTimeout = idleTimeout;

    Khadem.logger
        .info('🟢 HTTP Server started on http://${host ?? 'localhost'}:$port');

    // Handle graceful shutdown
    final sub = ProcessSignal.sigint.watch().listen((signal) {
      Khadem.logger.info('🛑 Received signal $signal. Shutting down...');
      server.close().then((_) {
        Khadem.logger.info('👋 Server closed.');
        exit(0);
      });
    });

    try {
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
            // Execute global middleware pipeline with the request processor as the final handler
            // This uses the optimized static execute method to avoid allocations
            await MiddlewarePipeline.execute(
              _middleware.pipeline.middleware,
              req,
              res,
              handler.handle,
            );
          } catch (e, stackTrace) {
            ExceptionHandler.handle(res, e, stackTrace);
          } finally {
            // Clean up request resources (e.g. temporary files)
            await req.cleanup();
          }
        });
      }
    } finally {
      await sub.cancel();
    }
  }
}

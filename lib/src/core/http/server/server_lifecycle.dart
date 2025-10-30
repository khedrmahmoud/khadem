import 'dart:async';
import 'dart:io';

import 'package:khadem/khadem.dart';

class ServerLifecycle {
  final ServerRouter _router;
  final ServerMiddleware _middleware;
  final ServerStatic _static;
  void Function()? _initializer;

  ServerLifecycle(this._router, this._middleware, this._static);

  void setInitializer(void Function() initializer) {
    _initializer = initializer;
  }

  Future<void> reload() async {
    // Fallback to manual reload
    if (_initializer != null) {
      _router.clear();
      _middleware.clear();
      _static.clear();
      _initializer!();
    }
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
    Khadem.logger
        .info('🟢 HTTP Server started on http://${host ?? 'localhost'}:$port');

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

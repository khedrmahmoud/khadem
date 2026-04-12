import 'dart:async';
import 'dart:io';

import 'package:khadem/contracts.dart' show ExceptionHandlerContract;
import 'package:khadem/support.dart' show Log, resolve;

import '../../routing/router.dart';
import '../context/server_context.dart';
import '../middleware/middleware_pipeline.dart';
import '../request/request.dart';
import '../response/response.dart';
import 'core/http_request_processor.dart';
import 'server_middleware.dart';
import 'server_static.dart';

class ServerLifecycle {
  final Router _router;
  final ServerMiddleware _middleware;
  final ServerStatic _static;

  HttpServer? _server;
  StreamSubscription? _signalSubscription;

  // Configuration
  bool autoCompress = true;
  Duration idleTimeout = const Duration(seconds: 120);

  ServerLifecycle(this._router, this._middleware, this._static);

  Future<void> reload() async {
    // Fallback to manual reload
    _router.routes.clear();
    _middleware.clear();
    _static.clear();
  }

  Future<void> stop() async {
    await _server?.close();
    await _signalSubscription?.cancel();
    _server = null;
  }

  Future<void> start({int port = 8080, String? host}) async {
    final handler = HttpRequestProcessor(
      router: _router,
      globalMiddleware: _middleware.pipeline,
      staticHandler: _static.staticHandler,
    );

    _server = await HttpServer.bind(
      host != null ? InternetAddress(host) : InternetAddress.anyIPv4,
      port,
      shared: true,
    );

    final server = _server!;

    // Enable compression and set idle timeout
    server.autoCompress = autoCompress;
    server.idleTimeout = idleTimeout;

    Log.info('🟢 HTTP Server started on http://${host ?? 'localhost'}:$port');

    // Handle graceful shutdown
    _signalSubscription = ProcessSignal.sigint.watch().listen((signal) {
      Log.info('🛑 Received signal $signal. Shutting down...');
      stop().then((_) {
        Log.info('👋 Server closed.');
        exit(0);
      });
    });

    try {
      await for (final raw in server) {
        final req = Request(raw);
        final res = Response(raw);

        Zone.current
            .fork(
              zoneValues: {
                ServerContext.zoneKey: ServerContext(
                  request: req,
                  response: res,
                ),
              },
            )
            .run(() async {
              try {
                // Execute global middleware pipeline with the request processor as the final handler
                // This uses the optimized static execute method to avoid allocations
                await MiddlewarePipeline.execute(
                  _middleware.pipeline.middleware,
                  req,
                  res,
                  (request, response) {
                    if (response is! Response) {
                      throw StateError(
                        'HTTP server lifecycle requires a concrete Response instance.',
                      );
                    }
                    return handler.handle(request, response);
                  },
                );
              } catch (e, stackTrace) {
                final exceptionHandler = resolve<ExceptionHandlerContract>();
                final result = await exceptionHandler.handle(e, stackTrace);

                if (!res.sent) {
                  res
                      .status(result.statusCode)
                      .problem(
                        title: result.title,
                        status: result.statusCode,
                        detail: result.message,
                        type: result.type,
                        instance: result.instance,
                        extensions: {
                          if (result.details != null) 'details': result.details,
                          if (result.stackTrace != null)
                            'stack_trace': result.stackTrace.toString(),
                          ...result.extensions,
                        },
                      );
                }
              } finally {
                // Clean up request resources (e.g. temporary files)
                await req.cleanup();
              }
            });
      }
    } finally {
      await _signalSubscription?.cancel();
    }
  }
}

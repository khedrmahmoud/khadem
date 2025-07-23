import 'dart:async';
import 'dart:io';

import '../../../contracts/http/middleware_contract.dart';
import '../../exception/exception_handler.dart';
import '../../routing/router.dart';
import '../context/request_context.dart';
import '../context/response_context.dart';
import '../../../types/handler.dart';
import '../context/server_context.dart';
import '../middleware/middleware_pipeline.dart';
import '../request/request.dart';
import '../response/response.dart';
import 'core/request_handler.dart';
import 'core/static_handler.dart';

/// 🔥 The core HTTP server for Khadem.
///
/// Provides routing, middleware pipeline, static file serving,
/// and request handling similar to frameworks like Express.js or Laravel.
class Server {
  final Router _router = Router();
  final MiddlewarePipeline _pipeline = MiddlewarePipeline();
  static ServerStaticHandler? _staticHandler;
// Store the initializer function to reload routes/middleware
  void Function(Server server)? _initializer;
  // ========================================
  // 📁 Static File Serving
  // ========================================

  /// Serves static files from a given [path].
  ///
  /// Example:
  /// ```dart
  /// server.serveStatic('public');
  /// ```
  void serveStatic(String path) {
    _staticHandler = ServerStaticHandler(path);
  }

  // ========================================
  // ⚙️ Middleware Management
  // ========================================

  /// Registers a single global middleware [handler].
  ///
  /// Optionally set [priority] or [name] for ordering and debugging.
  void useMiddleware(MiddlewareHandler handler,
      {MiddlewarePriority priority = MiddlewarePriority.global, String? name}) {
    _pipeline.add(handler, priority: priority, name: name);
  }

  /// Registers multiple global [middlewares].
  ///
  /// These are executed for every incoming request.
  void useMiddlewares(List<Middleware> middlewares) {
    _pipeline.addMiddlewares(middlewares);
  }

  // ========================================
  // 🔁 Route Registration
  // ========================================

  void get(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      _router.get(path, handler, middleware: middleware);

  void post(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      _router.post(path, handler, middleware: middleware);

  void put(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      _router.put(path, handler, middleware: middleware);

  void patch(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      _router.patch(path, handler, middleware: middleware);

  void delete(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      _router.delete(path, handler, middleware: middleware);

  void head(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      _router.head(path, handler, middleware: middleware);

  void options(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      _router.options(path, handler, middleware: middleware);

  // ========================================
  // 📦 Route Grouping
  // ========================================

  /// Groups multiple routes under a common [prefix] and optional [middleware].
  ///
  /// Example:
  /// ```dart
  /// server.group(
  ///   prefix: '/api',
  ///   middleware: [AuthMiddleware()],
  ///   routes: (router) {
  ///     router.get('/users', getUsersHandler);
  ///   },
  /// );
  /// ```
  void group({
    required String prefix,
    List<Middleware> middleware = const [],
    required void Function(Router router) routes,
  }) {
    final groupRouter = Router();
    routes(groupRouter);

    for (final route in groupRouter.routes) {
      _router.register(
        route.method,
        '$prefix${route.path}',
        route.handler,
        [...middleware, ...route.middleware],
      );
    }
  }

// ========================================
  // 🔄 Hot Reload Support
  // ========================================

  void setInitializer(void Function(Server server) initializer) {
    _initializer = initializer;
  }

  Future<void> reload() async {
    if (_initializer != null) {
      // Reset router and pipeline
      _router.routes.clear();
      _pipeline.clear();
      // Re-run initializer to reload routes and middleware
      _initializer!(this);
      print('Routes and middleware reloaded');
    }
  }

  // ========================================
  // 🚀 Start the Server
  // ========================================

  /// Starts the HTTP server on the specified [port].
  ///
  /// Automatically applies global middleware and routes.
  Future<void> start({int port = 8080}) async {
    final handler = RequestHandler(
      router: _router,
      globalMiddleware: _pipeline,
      staticHandler: _staticHandler,
    );

    final server =
        await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);

    await for (final raw in server) {
      final req = Request(raw);
      final res = Response(raw);

      Zone.current.fork(
        zoneValues: {
          RequestContext.zoneKey: RequestContext.run(req, () => null),
          ResponseContext.zoneKey: ResponseContext.run(res, () => null),
          ServerContext.zoneKey: ServerContext(
            request: req,
            response: res,
            match: _router.match,
          ),
        },
      ).run(() async {
        try {
          await _pipeline.process(req, res);
          if (!res.sent) await handler.handle(req, res);
        } catch (e, s) {
          ExceptionHandler.handle(res, e, s);
        }
      });
    }
  }
}

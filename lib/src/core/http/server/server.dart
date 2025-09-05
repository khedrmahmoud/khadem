import '../../../contracts/http/middleware_contract.dart';
import '../request/request_handler.dart';
import '../../routing/router.dart';
import 'server_lifecycle.dart';
import 'server_middleware.dart';
import 'server_router.dart';
import 'server_static.dart';

/// 🔥 The core HTTP server for Khadem.
///
/// Provides routing, middleware pipeline, static file serving,
/// and request handling similar to frameworks like Express.js or Laravel.
///
/// This class orchestrates modular components for better maintainability
/// and separation of concerns.
class Server {
  late final ServerRouter _router;
  late final ServerMiddleware _middleware;
  late final ServerStatic _static;
  late final ServerLifecycle _lifecycle;

  Server() {
    _router = ServerRouter();
    _middleware = ServerMiddleware();
    _static = ServerStatic();
    _lifecycle = ServerLifecycle(_router, _middleware, _static);
  }

  // ========================================
  // 📁 Static File Serving
  // ========================================

  /// Serves static files from a given [path].
  ///
  /// Example:
  /// ```dart
  /// server.serveStatic('public');
  /// ```
  void serveStatic([String path = 'public']) {
    _static.serveStatic(path);
  }

  // ========================================
  // ⚙️ Middleware Management
  // ========================================

  /// Registers a single global middleware [handler].
  ///
  /// Optionally set [priority] or [name] for ordering and debugging.
  void useMiddleware(
    MiddlewareHandler handler, {
    MiddlewarePriority priority = MiddlewarePriority.global,
    String? name,
  }) {
    _middleware.useMiddleware(handler, priority: priority, name: name);
  }

  /// Registers multiple global [middlewares].
  ///
  /// These are executed for every incoming request.
  void useMiddlewares(List<Middleware> middlewares) {
    _middleware.useMiddlewares(middlewares);
  }

  // ========================================
  // 🔁 Route Registration
  // ========================================

  void get(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
  }) =>
      _router.get(path, handler, middleware: middleware);

  void post(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
  }) =>
      _router.post(path, handler, middleware: middleware);

  void put(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
  }) =>
      _router.put(path, handler, middleware: middleware);

  void patch(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
  }) =>
      _router.patch(path, handler, middleware: middleware);

  void delete(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
  }) =>
      _router.delete(path, handler, middleware: middleware);

  void head(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
  }) =>
      _router.head(path, handler, middleware: middleware);

  void options(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
  }) =>
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
    required void Function(Router router) routes,
    List<Middleware> middleware = const [],
  }) {
    _router.group(prefix: prefix, routes: routes, middleware: middleware);
  }

  // ========================================
  // 🔄 Hot Reload Support
  // ========================================

  void setInitializer(void Function() initializer) {
    _lifecycle.setInitializer(initializer);
  }

  Future<void> reload() async {
    await _lifecycle.reload();
    _injectReload();
  }

  /// Reloading enpoint when call reload the server
  ///
  /// Injects a reloading endpoint when the server is reloaded.
  void _injectReload() {
    // Add a POST endpoint for triggering reload
    _router.post('/reload', (req, res) async {
      await _lifecycle.reload();
      res.sendJson({'message': 'Server reloaded successfully'});
    });
  }

// ========================================
// 🚀 Start the Server
// ========================================

  /// Starts the HTTP server on the specified [port].
  ///
  /// Automatically applies global middleware and routes.
  Future<void> start({int port = 8080}) async {
    _injectReload(); // Inject the reload endpoint
    await _lifecycle.start(port: port);
  }
}

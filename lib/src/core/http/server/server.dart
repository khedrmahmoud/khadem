import 'package:khadem/src/application/khadem.dart';

import '../../../contracts/http/middleware_contract.dart';
import 'server_lifecycle.dart';
import 'server_middleware.dart';
import 'server_router.dart';
import 'server_static.dart';

/// Core HTTP server for Khadem.
///
/// Orchestrates routing, global middleware, static file serving and
/// lifecycle operations. Routing configuration should be provided via
/// `injectRoutes` so route definitions live in a single place.
class Server {
  late final ServerRouter _serverRouter;
  late final ServerMiddleware _serverMiddleware;
  late final ServerStatic _staticHandler;
  late final ServerLifecycle _serverLifecycle;

  Server() {
    _serverRouter = ServerRouter();
    _serverMiddleware = ServerMiddleware();
    _staticHandler = ServerStatic();
    _serverLifecycle =
        ServerLifecycle(_serverRouter, _serverMiddleware, _staticHandler);
  }

  /// Serve files from [path] (defaults to `public`).
  void serveStatic([String path = 'public']) =>
      _staticHandler.serveStatic(path);

  /// Register a global middleware handler.
  void addMiddlewareHandler(
    MiddlewareHandler handler, {
    MiddlewarePriority priority = MiddlewarePriority.global,
    String? name,
  }) {
    _serverMiddleware.useMiddleware(handler, priority: priority, name: name);
  }

  /// Register multiple global middlewares.
  void applyMiddlewares(List<Middleware> middlewares) =>
      _serverMiddleware.useMiddlewares(middlewares);

  /// Inject route definitions into the server's internal router.
  ///
  /// Example:
  /// ```dart
  /// server.injectRoutes((router) {
  ///   router.group(prefix: '/api', middleware: [AuthMiddleware()], (r) {
  ///     r.get('/users', UsersController.index);
  ///   });
  /// });
  /// ```
  void injectRoutes(void Function(ServerRouter router) register) =>
      register(_serverRouter);

  /// Trigger a lifecycle reload. In development, lightweight endpoints are
  /// injected to allow manual reloads.
  Future<void> reload() async {
    await _serverLifecycle.reload();
    _injectDevEndpoints();
  }

  /// Inject development-only endpoints (`/reload`).
  void _injectDevEndpoints() {
    if (Khadem.isDevelopment) {
      _serverRouter.get('/reload', (req, res) async {
        await _serverLifecycle.reload();
        res.sendJson({'message': 'Server reloaded successfully'});
      });
    }
  }

  /// Start the HTTP server on [port] and optional [host].
  Future<void> start({int port = 8080, String? host}) async {
    _injectDevEndpoints();
    await _serverLifecycle.start(port: port, host: host);
  }
}

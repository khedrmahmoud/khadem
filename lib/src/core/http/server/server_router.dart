import '../../../contracts/http/middleware_contract.dart';
import '../../routing/router.dart';
import '../request/request_handler.dart';

/// Handles route registration and grouping for the server.
class ServerRouter {
  final Router _router = Router();

  Router get router => _router;

  /// Registers a GET route.
  void get(String path, RequestHandler handler,
      {List<Middleware> middleware = const []}) =>
    _router.get(path, handler, middleware: middleware);

  /// Registers a POST route.
  void post(String path, RequestHandler handler,
      {List<Middleware> middleware = const []}) =>
    _router.post(path, handler, middleware: middleware);

  /// Registers a PUT route.
  void put(String path, RequestHandler handler,
      {List<Middleware> middleware = const []}) =>
    _router.put(path, handler, middleware: middleware);

  /// Registers a PATCH route.
  void patch(String path, RequestHandler handler,
      {List<Middleware> middleware = const []}) =>
    _router.patch(path, handler, middleware: middleware);

  /// Registers a DELETE route.
  void delete(String path, RequestHandler handler,
      {List<Middleware> middleware = const []}) =>
    _router.delete(path, handler, middleware: middleware);

  /// Registers a HEAD route.
  void head(String path, RequestHandler handler,
      {List<Middleware> middleware = const []}) =>
    _router.head(path, handler, middleware: middleware);

  /// Registers an OPTIONS route.
  void options(String path, RequestHandler handler,
      {List<Middleware> middleware = const []}) =>
    _router.options(path, handler, middleware: middleware);

  /// Groups multiple routes under a common prefix and optional middleware.
  ///
  /// Example:
  /// ```dart
  /// serverRouter.group(
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

  /// Clears all registered routes.
  void clear() {
    _router.routes.clear();
  }
}

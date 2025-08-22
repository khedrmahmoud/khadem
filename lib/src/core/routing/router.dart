import '../../contracts/http/middleware_contract.dart';
import '../exception/exception_handler.dart';
import '../../types/handler.dart';
import 'route.dart';
import 'route_group.dart';
import 'route_match_result.dart';

/// Manages routing logic with support for HTTP methods and middleware.
class Router {
  final List<Route> _routes = [];

  /// Returns the list of registered routes.
  List<Route> get routes => _routes;

  /// Registers a route with the specified [method], [path], [handler], and optional [middleware].
  void register(String method, String path, Handler handler,
      List<Middleware> middleware) {
    final route = Route(method.toUpperCase(), path, handler, middleware);
    if (route.isDynamic) {
      _routes.add(route);
    } else {
      _routes.insert(0, route);
    }
  }

  /// Registers a GET route.
  void get(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      register('GET', path, handler, middleware);

  /// Registers a POST route.
  void post(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      register('POST', path, handler, middleware);

  /// Registers a PUT route.
  void put(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      register('PUT', path, handler, middleware);

  /// Registers a PATCH route.
  void patch(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      register('PATCH', path, handler, middleware);

  /// Registers a DELETE route.
  void delete(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      register('DELETE', path, handler, middleware);

  /// Registers a HEAD route.
  void head(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      register('HEAD', path, handler, middleware);

  /// Registers an OPTIONS route.
  void options(String path, Handler handler,
          {List<Middleware> middleware = const []}) =>
      register('OPTIONS', path, handler, middleware);

  /// Registers a route for any method.
  void any(String path, Handler handler,
      {List<Middleware> middleware = const []}) {
    for (final method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']) {
      register(method, path, handler, middleware);
    }
  }

  /// Groups a set of routes under a prefix and optional middleware.
  void group({
    required String prefix,
    List<Middleware> middleware = const [],
    required void Function(Router) routes,
  }) {
    final group = RouteGroup(
      prefix: prefix,
      middleware: middleware,
      defineRoutes: routes,
    );
    group.register(this);
  }

  /// Matches a route for the given [method] and [path].
  /// Matches the first route that fits the given method and path.
  RouteMatchResult? match(String method, String path) {
    for (final route in _routes) {
      if (route.matches(method, path)) {
        return RouteMatchResult(
          handler: wrapWithHandler(route.handler),
          params: route.extractParams(path),
          middleware: route.middleware,
        );
      }
    }
    return null;
  }

  Handler wrapWithHandler(Handler handler) {
    return (req, res) async {
      try {
        await handler(req, res);
      } catch (e, s) {
        ExceptionHandler.handle(res, e, s);
      }
    };
  }
}

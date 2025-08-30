import '../../contracts/http/middleware_contract.dart';
import '../http/request/request_handler.dart';
import 'route.dart';

/// Handles route registration and storage.
class RouteRegistry {
  final List<Route> _routes = [];

  /// Returns the list of registered routes.
  List<Route> get routes => _routes;

  /// Registers a route with the specified parameters.
  void register(String method, String path, RequestHandler handler,
      List<Middleware> middleware) {
    final route = Route(method.toUpperCase(), path, handler, middleware);
    if (route.isDynamic) {
      _routes.add(route);
    } else {
      _routes.insert(0, route);
    }
  }

  /// Registers a GET route.
  void get(String path, RequestHandler handler,
          {List<Middleware> middleware = const []}) =>
      register('GET', path, handler, middleware);

  /// Registers a POST route.
  void post(String path, RequestHandler handler,
          {List<Middleware> middleware = const []}) =>
      register('POST', path, handler, middleware);

  /// Registers a PUT route.
  void put(String path, RequestHandler handler,
          {List<Middleware> middleware = const []}) =>
      register('PUT', path, handler, middleware);

  /// Registers a PATCH route.
  void patch(String path, RequestHandler handler,
          {List<Middleware> middleware = const []}) =>
      register('PATCH', path, handler, middleware);

  /// Registers a DELETE route.
  void delete(String path, RequestHandler handler,
          {List<Middleware> middleware = const []}) =>
      register('DELETE', path, handler, middleware);

  /// Registers a HEAD route.
  void head(String path, RequestHandler handler,
          {List<Middleware> middleware = const []}) =>
      register('HEAD', path, handler, middleware);

  /// Registers an OPTIONS route.
  void options(String path, RequestHandler handler,
          {List<Middleware> middleware = const []}) =>
      register('OPTIONS', path, handler, middleware);

  /// Registers a route for any method.
  void any(String path, RequestHandler handler,
      {List<Middleware> middleware = const []}) {
    for (final method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']) {
      register(method, path, handler, middleware);
    }
  }

  /// Clears all registered routes.
  void clear() {
    _routes.clear();
  }
}

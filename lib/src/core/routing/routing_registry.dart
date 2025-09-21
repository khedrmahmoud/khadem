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
      List<Middleware> middleware, {String? name,}) {
    final route = Route(method.toUpperCase(), path, handler, middleware, name: name);
    if (route.isDynamic) {
      _routes.add(route);
    } else {
      _routes.insert(0, route);
    }
  }

  /// Registers a GET route.
  void get(String path, RequestHandler handler,
          {List<Middleware> middleware = const [], String? name,}) =>
      register('GET', path, handler, middleware, name: name);

  /// Registers a POST route.
  void post(String path, RequestHandler handler,
          {List<Middleware> middleware = const [], String? name,}) =>
      register('POST', path, handler, middleware, name: name);

  /// Registers a PUT route.
  void put(String path, RequestHandler handler,
          {List<Middleware> middleware = const [], String? name,}) =>
      register('PUT', path, handler, middleware, name: name);

  /// Registers a PATCH route.
  void patch(String path, RequestHandler handler,
          {List<Middleware> middleware = const [], String? name,}) =>
      register('PATCH', path, handler, middleware, name: name);

  /// Registers a DELETE route.
  void delete(String path, RequestHandler handler,
          {List<Middleware> middleware = const [], String? name,}) =>
      register('DELETE', path, handler, middleware, name: name);

  /// Registers a HEAD route.
  void head(String path, RequestHandler handler,
          {List<Middleware> middleware = const [], String? name,}) =>
      register('HEAD', path, handler, middleware, name: name);

  /// Registers an OPTIONS route.
  void options(String path, RequestHandler handler,
          {List<Middleware> middleware = const [], String? name,}) =>
      register('OPTIONS', path, handler, middleware, name: name);

  /// Registers a route for any method.
  void any(String path, RequestHandler handler,
      {List<Middleware> middleware = const [],}) {
    for (final method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']) {
      register(method, path, handler, middleware);
    }
  }

  /// Clears all registered routes.
  void clear() {
    _routes.clear();
  }

  /// Gets a route by name
  Route? getRouteByName(String name) {
    return _routes.where((route) => route.name == name).firstOrNull;
  }

  /// Gets all named routes
  Map<String, Route> getNamedRoutes() {
    final namedRoutes = <String, Route>{};
    for (final route in _routes) {
      if (route.isNamed) {
        namedRoutes[route.name!] = route;
      }
    }
    return namedRoutes;
  }
}

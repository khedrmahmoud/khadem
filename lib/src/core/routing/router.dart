import '../../contracts/http/middleware_contract.dart';
import '../http/request/request_handler.dart';
import 'route.dart';
import 'route_match_result.dart';
import 'routing_group_manager.dart';
import 'routing_handler.dart';
import 'routing_matcher.dart';
import 'routing_registry.dart';

/// Manages routing logic with support for HTTP methods and middleware.
///
/// This class orchestrates modular components for better maintainability
/// and separation of concerns.
class Router {
  late final RouteRegistry _registry;
  late final RouteGroupManager _groupManager;
  late final RouteHandler _handler;

  // Cache the matcher to avoid rebuilding the routing table on every request
  RouteMatcher? _matcher;

  Router() {
    _registry = RouteRegistry();
    _groupManager = RouteGroupManager(_registry);
    _handler = RouteHandler();
  }

  /// Private constructor for internal use with existing registry
  Router._withRegistry(RouteRegistry registry) {
    _registry = registry;
    _groupManager = RouteGroupManager(_registry);
    _handler = RouteHandler();
  }

  /// Returns the list of registered routes.
  List<Route> get routes => _registry.routes;

  /// Invalidate the matcher cache when routes change
  void _invalidateCache() {
    _matcher = null;
  }

  /// Registers a route with the specified [method], [path], [handler], and optional [middleware].
  void register(
    String method,
    String path,
    RequestHandler handler,
    List<Middleware> middleware, {
    String? name,
  }) {
    _registry.register(method, path, handler, middleware, name: name);
    _invalidateCache();
  }

  /// Registers a GET route.
  void get(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
    _registry.get(path, handler, middleware: middleware, name: name);
    _invalidateCache();
  }

  /// Registers a POST route.
  void post(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
    _registry.post(path, handler, middleware: middleware, name: name);
    _invalidateCache();
  }

  /// Registers a PUT route.
  void put(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
    _registry.put(path, handler, middleware: middleware, name: name);
    _invalidateCache();
  }

  /// Registers a PATCH route.
  void patch(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
    _registry.patch(path, handler, middleware: middleware, name: name);
    _invalidateCache();
  }

  /// Registers a DELETE route.
  void delete(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
    _registry.delete(path, handler, middleware: middleware, name: name);
    _invalidateCache();
  }

  /// Registers a HEAD route.
  void head(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
    _registry.head(path, handler, middleware: middleware, name: name);
    _invalidateCache();
  }

  /// Registers an OPTIONS route.
  void options(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
    String? name,
  }) {
    _registry.options(path, handler, middleware: middleware, name: name);
    _invalidateCache();
  }

  /// Registers a route for any method.
  void any(
    String path,
    RequestHandler handler, {
    List<Middleware> middleware = const [],
  }) {
    _registry.any(path, handler, middleware: middleware);
    _invalidateCache();
  }

  /// Groups a set of routes under a prefix and optional middleware.
  void group({
    required String prefix,
    required void Function(Router) routes,
    List<Middleware> middleware = const [],
  }) {
    _groupManager.group(
      prefix: prefix,
      routes: (registry) {
        // Create a temporary router that uses the registry
        final tempRouter = Router._withRegistry(registry);
        routes(tempRouter);
      },
      middleware: middleware,
    );
    _invalidateCache();
  }

  /// Matches a route for the given [method] and [path].
  /// Matches the first route that fits the given method and path.
  RouteMatchResult? match(String method, String path) {
    _matcher ??= RouteMatcher(_registry.routes);
    final result = _matcher!.match(method, path);
    if (result != null) {
      return RouteMatchResult(
        handler: _handler.wrapWithExceptionHandler(result.handler),
        params: result.params,
        middleware: result.middleware,
      );
    }
    return null;
  }

  /// Clears all registered routes.
  void clear() {
    _registry.clear();
    _invalidateCache();
  }
}

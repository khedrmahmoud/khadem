import 'route.dart';
import 'route_match_result.dart';

/// Handles route matching logic with performance optimization.
///
/// Separates static and dynamic routes for faster lookup:
/// - Static routes: O(1) hash map lookup
/// - Dynamic routes: O(n) sequential search (but smaller n)
class RouteMatcher {
  final List<Route> _routes;
  
  /// Fast lookup for static routes: Map<Method, Map<Path, Route>>
  /// Example: {'GET': {'/users': Route1, '/posts': Route2}}
  final Map<String, Map<String, Route>> _staticRoutes = {};
  
  /// Dynamic routes with parameters (smaller list to iterate)
  final List<Route> _dynamicRoutes = [];

  RouteMatcher(this._routes) {
    _categorizeRoutes();
  }
  
  /// Categorizes routes into static and dynamic for optimized lookup
  void _categorizeRoutes() {
    for (final route in _routes) {
      if (route.isDynamic) {
        _dynamicRoutes.add(route);
      } else {
        // Static route: store in hash map by method and path
        _staticRoutes.putIfAbsent(route.method, () => {});
        _staticRoutes[route.method]![route.path] = route;
      }
    }
  }

  /// Matches a route for the given method and path.
  /// Returns the first route that fits the given method and path.
  ///
  /// Performance:
  /// - Static routes: O(1) hash map lookup
  /// - Dynamic routes: O(n) where n = number of dynamic routes only
  RouteMatchResult? match(String method, String path) {
    // Normalize the incoming path for consistent matching
    final normalizedPath = _normalizePath(path);
    
    // Try static routes first (O(1) lookup)
    if (_staticRoutes[method]?.containsKey(normalizedPath) ?? false) {
      final route = _staticRoutes[method]![normalizedPath]!;
      return RouteMatchResult(
        handler: route.handler,
        params: {}, // Static routes have no params
        middleware: route.middleware,
      );
    }
    
    // Fallback to dynamic routes (O(n) but smaller n)
    for (final route in _dynamicRoutes) {
      if (route.matches(method, path)) {
        return RouteMatchResult(
          handler: route.handler,
          params: route.extractParams(path),
          middleware: route.middleware,
        );
      }
    }
    
    return null;
  }
  
  /// Normalizes a path by removing trailing slashes
  /// Preserves root path '/' as-is
  static String _normalizePath(String path) {
    if (path == '/' || path.isEmpty) {
      return '/';
    }
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  /// Finds all routes that match the given method and path.
  /// Useful for debugging or advanced routing scenarios.
  List<RouteMatchResult> findAllMatches(String method, String path) {
    final matches = <RouteMatchResult>[];
    final normalizedPath = _normalizePath(path);

    // Check static routes
    if (_staticRoutes[method]?.containsKey(normalizedPath) ?? false) {
      final route = _staticRoutes[method]![normalizedPath]!;
      matches.add(
        RouteMatchResult(
          handler: route.handler,
          params: {},
          middleware: route.middleware,
        ),
      );
    }

    // Check dynamic routes
    for (final route in _dynamicRoutes) {
      if (route.matches(method, path)) {
        matches.add(
          RouteMatchResult(
            handler: route.handler,
            params: route.extractParams(path),
            middleware: route.middleware,
          ),
        );
      }
    }

    return matches;
  }

  /// Checks if any route matches the given method and path.
  bool hasMatch(String method, String path) {
    final normalizedPath = _normalizePath(path);
    
    // Check static routes first (fast)
    if (_staticRoutes[method]?.containsKey(normalizedPath) ?? false) {
      return true;
    }
    
    // Check dynamic routes
    return _dynamicRoutes.any((route) => route.matches(method, path));
  }
}

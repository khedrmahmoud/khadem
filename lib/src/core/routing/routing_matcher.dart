import 'route.dart';
import 'route_match_result.dart';

/// Handles route matching logic.
class RouteMatcher {
  final List<Route> _routes;

  RouteMatcher(this._routes);

  /// Matches a route for the given method and path.
  /// Returns the first route that fits the given method and path.
  RouteMatchResult? match(String method, String path) {
    for (final route in _routes) {
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

  /// Finds all routes that match the given method and path.
  /// Useful for debugging or advanced routing scenarios.
  List<RouteMatchResult> findAllMatches(String method, String path) {
    final matches = <RouteMatchResult>[];

    for (final route in _routes) {
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
    return _routes.any((route) => route.matches(method, path));
  }
}

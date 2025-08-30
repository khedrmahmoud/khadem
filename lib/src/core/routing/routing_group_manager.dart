import '../../contracts/http/middleware_contract.dart';
import 'routing_registry.dart';

/// Handles route grouping functionality.
class RouteGroupManager {
  final RouteRegistry _registry;

  RouteGroupManager(this._registry);

  /// Groups a set of routes under a prefix and optional middleware.
  void group({
    required String prefix,
    required void Function(RouteRegistry registry) routes,
    List<Middleware> middleware = const [],
  }) {
    final groupRegistry = RouteRegistry();
    routes(groupRegistry);

    for (final route in groupRegistry.routes) {
      final newPath = '$prefix${route.path}';
      _registry.register(
        route.method,
        newPath,
        route.handler,
        [...middleware, ...route.middleware],
      );
    }
  }
}

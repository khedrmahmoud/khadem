import '../../contracts/http/middleware_contract.dart';
import 'router.dart';

/// Route group config object.
///
/// This class is used to group routes together and define them in a closure.
/// It also allows you to define middleware for the group of routes.
class RouteGroup {
  /// The prefix for the routes in this group.
  final String prefix;

  /// The middleware for this group of routes.
  final List<Middleware> middleware;

  /// The closure that defines the routes for this group.
  final void Function(Router router) defineRoutes;

  /// Creates a new instance of [RouteGroup].
  ///
  /// The [prefix] parameter is used to define the prefix for the routes in
  /// this group. The [middleware] parameter is used to define the middleware
  /// for this group of routes. The [defineRoutes] parameter is a closure that
  /// defines the routes for this group.
  RouteGroup({
    this.prefix = '',
    this.middleware = const [],
    required this.defineRoutes,
  });

  /// Registers the routes for this group with the given [router].
  ///
  /// This method is used to register the routes for this group with a given
  /// [Router] instance. The routes are registered with the prefix and middleware
  /// defined for this group.
  void register(Router router) {
    final subRouter = Router();
    defineRoutes(subRouter);

    for (final route in subRouter.routes) {
      final newPath = '$prefix${route.path}';
      router.register(
        route.method,
        newPath,
        route.handler,
        [...middleware, ...route.middleware],
      );
    }
  }
}

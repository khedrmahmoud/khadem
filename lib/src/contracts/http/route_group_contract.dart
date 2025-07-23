import 'middleware_contract.dart';

/// Contract that defines route group behavior such as prefix and attached middleware.
abstract class RouteGroupContract {
  /// Common prefix for all routes in the group.
  String get prefix;

  /// List of middleware to apply to all routes in the group.
  List<Middleware> get middleware;
}

import '../../contracts/http/middleware_contract.dart';
import '../http/request/request_handler.dart';

/// Represents the result of a matched route.
///
/// This class is an Application Programming Interface (API) Object Representation (Apro)
/// of the route matching result. It contains the matched route's [RequestHandler], the
/// extracted URL parameters, and the middleware that should be executed for this
/// route.
class RouteMatchResult {
  final RequestHandler handler;
  final Map<String, String> params;
  final List<Middleware> middleware;

  RouteMatchResult({
    required this.handler,
    required this.params,
    required this.middleware,
  });
}

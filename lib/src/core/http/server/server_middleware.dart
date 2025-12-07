import '../../../contracts/http/middleware_contract.dart';
import '../middleware/middleware_pipeline.dart';

/// Handles middleware management for the server.
class ServerMiddleware {
  final MiddlewarePipeline _pipeline = MiddlewarePipeline();

  MiddlewarePipeline get pipeline => _pipeline;

  /// Registers a single global middleware handler.
  ///
  /// Optionally set priority or name for ordering and debugging.
  void useMiddleware(
    MiddlewareHandler handler, {
    MiddlewarePriority priority = MiddlewarePriority.global,
    String? name,
  }) {
    _pipeline.add(handler, priority: priority, name: name);
  }

  /// Registers multiple global middlewares.
  ///
  /// These are executed for every incoming request.
  void useMiddlewares(List<Middleware> middlewares) {
    _pipeline.addMiddlewares(middlewares);
  }

  /// Registers a group of middleware.
  void group(String name, List<Middleware> middlewares) {
    _pipeline.group(name, middlewares);
  }

  /// Uses a registered group of middleware.
  void useGroup(String name) {
    _pipeline.useGroup(name);
  }

  /// Gets a registered group of middleware.
  List<Middleware> getGroup(String name) {
    return _pipeline.getGroup(name);
  }

  /// Clears all registered middleware.
  void clear() {
    _pipeline.clear();
  }
}

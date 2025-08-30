import '../../../contracts/http/middleware_contract.dart';
import '../middleware/middleware_pipeline.dart';

/// Handles middleware management for the server.
class ServerMiddleware {
  final MiddlewarePipeline _pipeline = MiddlewarePipeline();

  MiddlewarePipeline get pipeline => _pipeline;

  /// Registers a single global middleware handler.
  ///
  /// Optionally set priority or name for ordering and debugging.
  void useMiddleware(MiddlewareHandler handler,
      {MiddlewarePriority priority = MiddlewarePriority.global, String? name}) {
    _pipeline.add(handler, priority: priority, name: name);
  }

  /// Registers multiple global middlewares.
  ///
  /// These are executed for every incoming request.
  void useMiddlewares(List<Middleware> middlewares) {
    _pipeline.addMiddlewares(middlewares);
  }

  /// Clears all registered middleware.
  void clear() {
    _pipeline.clear();
  }
}

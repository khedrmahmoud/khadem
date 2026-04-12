import 'dart:async';

import '../../../contracts/http/middleware_contract.dart';
import '../../../contracts/http/response_contract.dart';
import '../../../support/exceptions/middleware_not_found_exception.dart';
import '../request/request.dart';

/// Enhanced middleware pipeline with priority-based execution and better error handling.
///
/// This class manages a collection of middleware handlers that process HTTP requests
/// in a specific order based on their priority levels. It supports:
/// - Priority-based execution (global -> routing -> auth -> preprocessing -> business -> terminating)
/// - Named middleware for easy reference and ordering
/// - Error handling with terminating middleware
/// - Dynamic addition/removal of middleware
/// - Before/after insertion relative to named middleware
///
/// Example usage:
/// ```dart
/// final pipeline = MiddlewarePipeline();
///
/// // Add middleware with different priorities
/// pipeline.add((req, res, next) async {
///   print('Global middleware');
///   await next();
/// }, priority: MiddlewarePriority.global, name: 'logger');
///
/// pipeline.add((req, res, next) async {
///   print('Auth middleware');
///   await next();
/// }, priority: MiddlewarePriority.auth, name: 'auth');
///
/// // Process request
/// await pipeline.process(request, response);
/// ```
class MiddlewarePipeline {
  final List<Middleware> _middleware = [];
  final Map<String, Middleware> _namedMiddleware = {};
  final Map<String, List<Middleware>> _groups = {};

  /// Adds a middleware handler function to the pipeline.
  void add(
    MiddlewareHandler handler, {
    MiddlewarePriority priority = MiddlewarePriority.business,
    String? name,
  }) {
    final middleware = Middleware(handler, priority: priority, name: name);
    addMiddleware(middleware);
  }

  /// Adds a full middleware object to the pipeline.
  void addMiddleware(Middleware middleware) {
    _middleware.add(middleware);

    _namedMiddleware[middleware.name] = middleware;

    _sortMiddleware();
  }

  /// Adds multiple middleware handlers to the pipeline.
  void addAll(
    List<MiddlewareHandler> handlers, {
    MiddlewarePriority priority = MiddlewarePriority.business,
  }) {
    for (final handler in handlers) {
      add(handler, priority: priority);
    }
  }

  /// Adds multiple middleware objects to the pipeline.
  void addMiddlewares(List<Middleware> middlewares) {
    for (final middleware in middlewares) {
      addMiddleware(middleware);
    }
  }

  /// Registers a group of middleware.
  void group(String name, List<Middleware> middlewares) {
    _groups[name] = middlewares;
  }

  /// Adds a registered group of middleware to the pipeline.
  void useGroup(String name) {
    if (!_groups.containsKey(name)) {
      throw MiddlewareNotFoundException('Middleware group not found: $name');
    }
    addMiddlewares(_groups[name]!);
  }

  /// Gets a registered group of middleware.
  List<Middleware> getGroup(String name) {
    if (!_groups.containsKey(name)) {
      throw MiddlewareNotFoundException('Middleware group not found: $name');
    }
    return _groups[name]!;
  }

  /// Adds a middleware before a specific named middleware.
  void addBefore(String targetName, MiddlewareHandler handler, {String? name}) {
    if (!_namedMiddleware.containsKey(targetName)) {
      throw MiddlewareNotFoundException(
        'Named middleware not found: $targetName',
      );
    }

    final target = _namedMiddleware[targetName]!;
    final middleware = Middleware(
      handler,
      priority: target.priority,
      name: name,
    );
    final index = _middleware.indexOf(target);
    _middleware.insert(index, middleware);

    if (name != null) {
      _namedMiddleware[name] = middleware;
    }
  }

  /// Adds a middleware after a specific named middleware.
  void addAfter(String targetName, MiddlewareHandler handler, {String? name}) {
    if (!_namedMiddleware.containsKey(targetName)) {
      throw MiddlewareNotFoundException(
        'Named middleware not found: $targetName',
      );
    }

    final target = _namedMiddleware[targetName]!;
    final middleware = Middleware(
      handler,
      priority: target.priority,
      name: name,
    );
    final index = _middleware.indexOf(target);
    _middleware.insert(index + 1, middleware);

    if (name != null) {
      _namedMiddleware[name] = middleware;
    }
  }

  /// Removes a middleware by name.
  void remove(String name) {
    if (_namedMiddleware.containsKey(name)) {
      final middleware = _namedMiddleware[name]!;
      _middleware.remove(middleware);
      _namedMiddleware.remove(name);
    }
  }

  /// Processes the request through the middleware pipeline.
  Future<void> process(Request request, ResponseContract response) async {
    await execute(
      _middleware,
      request,
      response,
      (req, res) async {}, // No-op final handler
    );
  }

  /// Sorts middleware by priority.
  void _sortMiddleware() {
    _middleware.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  /// Clears all middleware from the pipeline.
  void clear() {
    _middleware.clear();
    _namedMiddleware.clear();
  }

  /// Gets all middleware in the pipeline.
  List<Middleware> get middleware => List.unmodifiable(_middleware);

  /// Gets a middleware by name.
  Middleware? getByName(String name) => _namedMiddleware[name];

  /// Gets the count of middleware in the pipeline.
  int get count => _middleware.length;

  /// Checks if the pipeline is empty.
  bool get isEmpty => _middleware.isEmpty;

  /// Checks if the pipeline has any middleware.
  bool get isNotEmpty => _middleware.isNotEmpty;

  /// Gets middleware by priority level.
  List<Middleware> getMiddlewareByPriority(MiddlewarePriority priority) {
    return _middleware.where((m) => m.priority == priority).toList();
  }

  /// Gets all middleware names.
  List<String> get middlewareNames => _namedMiddleware.keys.toList();

  /// Executes middleware conditionally based on a predicate.
  void addConditional(
    MiddlewareHandler handler, {
    required bool Function(Request request) condition,
    MiddlewarePriority priority = MiddlewarePriority.business,
    String? name,
  }) {
    add(
      (req, res, next) async {
        if (condition(req)) {
          await handler(req, res, next);
        } else {
          await next();
        }
      },
      priority: priority,
      name: name,
    );
  }

  /// Checks if a named middleware exists.
  bool hasMiddleware(String name) => _namedMiddleware.containsKey(name);

  /// Executes a list of middleware in order, followed by a final handler.
  ///
  /// This static method avoids creating a [MiddlewarePipeline] instance and
  /// copying lists for every request, significantly reducing object allocation.
  static Future<void> execute(
    List<Middleware> middlewares,
    Request request,
    ResponseContract response,
    FutureOr<void> Function(Request, ResponseContract) finalHandler,
  ) async {
    var index = 0;

    Future<void> next() async {
      if (index < middlewares.length) {
        final middleware = middlewares[index++];
        try {
          await middleware.handler(request, response, next);
        } catch (e) {
          rethrow;
        }
      } else {
        // End of middleware chain, execute final handler
        await finalHandler(request, response);
      }
    }

    await next();
  }
}

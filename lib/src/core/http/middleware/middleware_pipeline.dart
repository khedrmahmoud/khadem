import 'dart:async';

import '../../../contracts/http/middleware_contract.dart';
import '../../../support/exceptions/middleware_not_found_exception.dart';
import '../request/request.dart';
import '../response/response.dart';

/// Enhanced middleware pipeline with priority-based execution and better error handling.
class MiddlewarePipeline {
  final List<Middleware> _middleware = [];
  final Map<String, Middleware> _namedMiddleware = {};

  /// Adds a middleware handler function to the pipeline.
  void add(MiddlewareHandler handler,
      {MiddlewarePriority priority = MiddlewarePriority.business,
      String? name}) {
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
  void addAll(List<MiddlewareHandler> handlers,
      {MiddlewarePriority priority = MiddlewarePriority.business}) {
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

  /// Adds a middleware before a specific named middleware.
  void addBefore(String targetName, MiddlewareHandler handler, {String? name}) {
    if (!_namedMiddleware.containsKey(targetName)) {
      throw MiddlewareNotFoundException(
          'Named middleware not found: $targetName');
    }

    final target = _namedMiddleware[targetName]!;
    final middleware =
        Middleware(handler, priority: target.priority, name: name);
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
          'Named middleware not found: $targetName');
    }

    final target = _namedMiddleware[targetName]!;
    final middleware =
        Middleware(handler, priority: target.priority, name: name);
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
  Future<void> process(Request request, Response response) async {
    var index = 0;

    Future<void> next() async {
      if (index < _middleware.length) {
        final middleware = _middleware[index++];
        try {
          await middleware.handler(request, response, next);
        } catch (e, stackTrace) {
          await _handleError(e, stackTrace, request, response);
        }
      }
    }

    await next();
  }

  /// Handles errors in the middleware pipeline.
  Future<void> _handleError(dynamic error, StackTrace stackTrace,
      Request request, Response response) async {
    final errorHandlers = _middleware
        .where((m) => m.priority == MiddlewarePriority.terminating)
        .toList();

    if (errorHandlers.isEmpty) {
      throw error;
    }

    request.params['error'] = error;
    request.params['stackTrace'] = stackTrace.toString();

    var handlerIndex = 0;

    Future<void> nextHandler() async {
      if (handlerIndex < errorHandlers.length) {
        final handler = errorHandlers[handlerIndex++];
        await handler.handler(request, response, nextHandler);
      }
    }

    await nextHandler();
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

  /// Checks if a named middleware exists.
  bool hasMiddleware(String name) => _namedMiddleware.containsKey(name);
}

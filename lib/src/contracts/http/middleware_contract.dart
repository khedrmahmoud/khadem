import 'dart:async';
import '../../core/http/request/request.dart';
import '../../core/http/response/response.dart';

/// Signature of a middleware function.
typedef MiddlewareHandler = FutureOr<void> Function(
    Request request, Response response, NextFunction next);

/// Signature for "next" callback in middleware chain.
typedef NextFunction = FutureOr<void> Function();

/// Priority levels for middleware execution.
enum MiddlewarePriority {
  global,
  routing,
  auth,
  preprocessing,
  business,
  terminating
}

/// Class representing a named and prioritized middleware instance.
class Middleware {
  final MiddlewareHandler _handler;
  final MiddlewarePriority _priority;
  final String _name;

  Middleware(this._handler,
      {MiddlewarePriority priority = MiddlewarePriority.business, String? name})
      : _priority = priority,
        _name = name ?? 'anonymous-${DateTime.now().millisecondsSinceEpoch}';

  MiddlewareHandler get handler => _handler;
  MiddlewarePriority get priority => _priority;
  String get name => _name;
}

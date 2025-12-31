import 'package:khadem/src/contracts/http/middleware_contract.dart';
import 'package:khadem/src/contracts/http/response_contract.dart';
import 'package:khadem/src/core/http/request/request.dart';

import '../facades/env.dart';

/// Middleware to update APP_URL in the environment for each request.
class DynamicAppUrlMiddleware implements Middleware {
  Future<void> handle(
    Request req,
    ResponseContract res,
    NextFunction next,
  ) async {
    final origin = req.origin;
    Env.set('APP_URL', origin);

    await next();
  }

  @override
  MiddlewareHandler get handler => handle;

  @override
  String get name => 'DynamicAppUrl';

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}

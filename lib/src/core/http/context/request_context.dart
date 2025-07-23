import 'dart:async';

import '../../../support/exceptions/missing_request_context_exception.dart';
import '../request/request.dart';
import '../../../modules/auth/auth.dart';

class RequestContext {
  static final _zoneKey = #requestContext;
  static get zoneKey => _zoneKey;

  /// Use this to access the current request in the zone.
  ///
  /// This can be useful when you need to access the request in a service or
  /// controller that is not directly called by the router.
  ///
  /// The request is stored in the zone when the request is processed by the
  /// router. Therefore, you can access the request in all services and
  /// controllers that are called by the router.
  ///
  /// If you need to access the request in a service or controller that is
  /// called outside of the request scope, you need to provide the request
  /// instance to the service or controller.
  static Request get request {
    final req = Zone.current[zoneKey] as Request?;
    if (req == null) {
      throw MissingRequestContextException();
    }
    return req;
  }

  /// This is a shorthand for [RequestContext.request.auth].
  static Auth get auth => Auth(request);

  /// Run anything inside this context.
  ///
  /// This is a profiled version of [runZoned] that will record the time it takes
  /// to run the provided function. The result will be logged to the console in
  /// the format:
  ///
  ///     [Profile] {functionName} took {time}ms
  static R run<R>(Request request, R Function() body) {
    return runZoned(body, zoneValues: {zoneKey: request});
  }
}

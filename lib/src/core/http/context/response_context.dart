import 'dart:async';

 

import '../../../support/exceptions/missing_response_context_exception.dart';
import '../response/response.dart';

class ResponseContext {
  static final _zoneKey = #responseContext;
  static get zoneKey => _zoneKey;

  /// Use this to access the current response in the zone.
  ///
  /// This can be useful when you need to access the response in a service or
  /// controller that is not directly called by the router.
  ///
  /// The response is stored in the zone when the request is processed by the
  /// router. Therefore, you can access the request in all services and
  /// controllers that are called by the router.
  ///
  /// If you need to access the request in a service or controller that is
  /// called outside of the request scope, you need to provide the request
  /// instance to the service or controller.
  static Response get response {
    final req = Zone.current[zoneKey] as Response?;
    if (req == null) {
      throw MissingResponseContextException();
    }
    return req;
  }

  /// Run anything inside this context.
  ///
  /// This is a profiled version of [runZoned] that will record the time it takes
  /// to run the provided function. The result will be logged to the console in
  /// the format:
  ///
  ///     [Profile] {functionName} took {time}ms
  static R run<R>(Response response, R Function() body) {
    return runZoned(body, zoneValues: {zoneKey: response});
  }
}

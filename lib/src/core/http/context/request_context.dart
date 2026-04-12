import 'dart:async';

import '../../../application/khadem.dart';
import '../../../modules/auth/auth.dart';
import '../request/request.dart';
import 'server_context.dart';

/// Provides access to the current HTTP request within a request processing zone.
///
/// This class enables services and controllers to access the current request
/// without having to pass it as a parameter through the call chain.
///
/// Key features:
/// - Zone-based request storage and retrieval
/// - Authentication shortcuts
/// - Per-request custom data storage
/// - Request profiling and timing
/// - Automatic cleanup of request-scoped data
class RequestContext {
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
  ///
  /// Throws [MissingServerContextException] if no request context is available.
  static Request get request {
    return ServerContext.current.request;
  }

  /// Check if a request context is currently available
  static bool get hasRequest {
    return ServerContext.hasContext;
  }

  /// This is a shorthand for [RequestContext.request.auth].
  static Auth get auth => Auth(request);

  /// Get the current user ID if authenticated
  static dynamic get userId => auth.id;

  /// Check if the current request is authenticated
  static bool get isAuthenticated => auth.check;

  /// Get the client IP address
  static String? get clientIp {
    try {
      final req = request;
      // Try X-Forwarded-For header first (for proxies/load balancers)
      final forwardedFor = req.headers.get('x-forwarded-for');
      if (forwardedFor != null && forwardedFor.isNotEmpty) {
        return forwardedFor.split(',').first.trim();
      }
      // Fall back to remote address
      return req.raw.connectionInfo?.remoteAddress.address;
    } catch (_) {
      return null;
    }
  }

  /// Get the User-Agent string
  static String? get userAgent => request.headers.get('user-agent');

  /// Get the Accept-Language header
  static String? get acceptLanguage => request.headers.get('accept-language');

  /// Get the Content-Type header
  static String? get contentType => request.headers.get('content-type');

  /// Get the Authorization header
  static String? get authorization => request.headers.get('authorization');

  /// Run anything inside this request context.
  ///
  /// This establishes a zone where the request is available via [RequestContext.request].
  /// The function will be executed and any request-scoped data will be cleaned up
  /// automatically when the function completes.
  ///
  /// Example:
  /// ```dart
  /// return RequestContext.run(request, () {
  ///   // Now RequestContext.request is available
  ///   final userId = RequestContext.userId;
  ///   return processRequest();
  /// });
  /// ```
  static R run<R>(Request request, R Function() body) {
    final stopwatch = Stopwatch()..start();
    try {
      return runZoned(() {
        final result = body();
        return result;
      }, zoneValues: {ServerContext.zoneKey: ServerContext(request: request)});
    } finally {
      stopwatch.stop();
      // Optional: Log slow requests
      if (stopwatch.elapsedMilliseconds > 1000) {
        Khadem.logger.warning(
          '[RequestContext] Slow request: ${request.method} ${request.path} took ${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }
  }

  /// Store custom data for the current request
  static void set(String key, dynamic value) {
    ServerContext.current.setData(key, value);
  }

  /// Retrieve custom data from the current request
  static T? get<T>(String key) {
    return ServerContext.current.getData<T>(key);
  }

  /// Check if custom data exists for the current request
  static bool has(String key) {
    return ServerContext.current.hasData(key);
  }

  /// Remove custom data from the current request
  static void remove(String key) {
    ServerContext.current.removeData(key);
  }

  /// Clear all custom data for the current request
  static void clear() {
    ServerContext.current.clearData();
  }

  /// Get all custom data for the current request
  static Map<String, dynamic> get allData {
    return ServerContext.current.allData;
  }

  /// Get the current request ID (useful for logging/tracing)
  static String get requestId {
    const key = '_request_id';
    var id = get<String>(key);
    if (id == null) {
      id = DateTime.now().millisecondsSinceEpoch.toString();
      set(key, id);
    }
    return id;
  }
}

import 'dart:async';

import '../../../support/exceptions/missing_response_context_exception.dart';
import '../response/response.dart';

/// Provides access to the current HTTP response within a request processing zone.
///
/// This class enables services and controllers to access the current response
/// without having to pass it as a parameter through the call chain.
///
/// Key features:
/// - Zone-based response storage and retrieval
/// - Response header management shortcuts
/// - Content type helpers
/// - Response timing and profiling
class ResponseContext {
  static const _zoneKey = #responseContext;
  static Symbol get zoneKey => _zoneKey;

  /// Use this to access the current response in the zone.
  ///
  /// This can be useful when you need to access the response in a service or
  /// controller that is not directly called by the router.
  ///
  /// The response is stored in the zone when the request is processed by the
  /// router. Therefore, you can access the response in all services and
  /// controllers that are called by the router.
  ///
  /// If you need to access the response in a service or controller that is
  /// called outside of the response scope, you need to provide the response
  /// instance to the service or controller.
  ///
  /// Throws [MissingResponseContextException] if no response context is available.
  static Response get response {
    final res = Zone.current[zoneKey] as Response?;
    if (res == null) {
      throw MissingResponseContextException();
    }
    return res;
  }

  /// Check if a response context is currently available
  static bool get hasResponse {
    try {
      return Zone.current[zoneKey] != null;
    } catch (_) {
      return false;
    }
  }

  /// Set the response status code
  static void status(int code) => response.status(code);

  /// Add a response header
  static void header(String name, String value) => response.header(name, value);

  /// Set Content-Type to JSON
  static void contentTypeJson() =>
      response.header('Content-Type', 'application/json');

  /// Set Content-Type to HTML
  static void contentTypeHtml() => response.header('Content-Type', 'text/html');

  /// Set Content-Type to XML
  static void contentTypeXml() =>
      response.header('Content-Type', 'application/xml');

  /// Set Content-Type to plain text
  static void contentTypeText() =>
      response.header('Content-Type', 'text/plain');

  /// Set Cache-Control header
  static void cacheControl(String value) =>
      response.header('Cache-Control', value);

  /// Set no-cache headers
  static void noCache() {
    response.header('Cache-Control', 'no-cache, no-store, must-revalidate');
    response.header('Pragma', 'no-cache');
    response.header('Expires', '0');
  }

  /// Set CORS headers
  static void cors({
    String allowOrigin = '*',
    String allowMethods = 'GET, POST, PUT, DELETE, OPTIONS',
    String allowHeaders = 'Content-Type, Authorization',
  }) {
    response.header('Access-Control-Allow-Origin', allowOrigin);
    response.header('Access-Control-Allow-Methods', allowMethods);
    response.header('Access-Control-Allow-Headers', allowHeaders);
  }

  /// Send a JSON response
  static void json(Map<String, dynamic> data) => response.sendJson(data);

  /// Send a plain text response
  static void text(String text) => response.send(text);

  /// Send an HTML response
  static void html(String html) {
    response.header('Content-Type', 'text/html');
    response.send(html);
  }

  /// Send a redirect response
  static Future<void> redirect(String url, {int status = 302}) =>
      response.redirect(url, status: status);

  /// Check if the response has been sent
  static bool get isSent => response.sent;

  /// Run anything inside this response context.
  ///
  /// This establishes a zone where the response is available via [ResponseContext.response].
  ///
  /// Example:
  /// ```dart
  /// return ResponseContext.run(response, () {
  ///   // Now ResponseContext.response is available
  ///   ResponseContext.status(200);
  ///   ResponseContext.json({'message': 'success'});
  /// });
  /// ```
  static R run<R>(Response response, R Function() body) {
    return runZoned(body, zoneValues: {zoneKey: response});
  }
}

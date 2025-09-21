import 'dart:io';

/// Handles HTTP header operations for requests.
class RequestHeaders {
  final HttpHeaders _headers;

  RequestHeaders(this._headers);

  /// Gets all HTTP headers.
  HttpHeaders get headers => _headers;

  /// Gets a header value by name (case-insensitive).
  String? header(String name) {
    return _headers.value(name);
  }

  /// Gets all values for a header name.
  List<String>? headerValues(String name) {
    return _headers[name];
  }

  /// Checks if a header exists.
  bool hasHeader(String name) {
    return _headers[name] != null;
  }

  /// Gets the Content-Type header.
  String? get contentType => header('content-type');

  /// Gets the User-Agent header.
  String? get userAgent => header('user-agent');

  /// Gets the Accept header.
  String? get accept => header('accept');

  /// Gets the Authorization header.
  String? get authorization => header('authorization');

  /// Gets the X-Forwarded-For header (for proxy support).
  String? get forwardedFor => header('x-forwarded-for');

  /// Gets the X-Real-IP header (for proxy support).
  String? get realIp => header('x-real-ip');

  /// Gets the Origin header.
  String? get origin => header('origin');

  /// Gets the Referer header.
  String? get referer => header('referer');

  /// Checks if the request accepts JSON responses.
  bool acceptsJson() {
    final accept = this.accept;
    return accept != null && accept.contains('application/json');
  }

  /// Checks if the request accepts HTML responses.
  bool acceptsHtml() {
    final accept = this.accept;
    return accept != null && accept.contains('text/html');
  }

  /// Checks if the request is from XMLHttpRequest (AJAX).
  bool isAjax() {
    return header('x-requested-with') == 'XMLHttpRequest';
  }

  /// Gets the host from the Host header.
  String? get host => header('host');
}

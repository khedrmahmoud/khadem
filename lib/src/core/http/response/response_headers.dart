import 'dart:io';

/// Handles HTTP response headers with a clean, consistent API.
///
/// This class provides methods for setting, getting, and managing HTTP response headers
/// with proper case-insensitive handling and convenient shortcuts for common headers.
class ResponseHeaders {
  final HttpResponse _response;

  ResponseHeaders(this._response);

  /// Sets a response header.
  void setHeader(String name, String value) {
    _response.headers.set(name, value);
  }

  /// Adds a response header (allows multiple values for the same header).
  void addHeader(String name, String value) {
    _response.headers.add(name, value);
  }

  /// Gets all values for a header.
  List<String>? getHeader(String name) {
    return _response.headers[name];
  }

  /// Gets the first value for a header.
  String? getFirstHeader(String name) {
    final values = getHeader(name);
    return values?.isNotEmpty == true ? values!.first : null;
  }

  /// Checks if a header exists.
  bool hasHeader(String name) {
    return _response.headers[name] != null;
  }

  /// Removes a header.
  void removeHeader(String name) {
    _response.headers.removeAll(name);
  }

  /// Clears all headers.
  void clearHeaders() {
    _response.headers.clear();
  }

  /// Sets the Content-Type header.
  void setContentType(ContentType contentType) {
    _response.headers.contentType = contentType;
  }

  /// Sets the Content-Type header from a string.
  void setContentTypeString(String contentType) {
    _response.headers.contentType = ContentType.parse(contentType);
  }

  /// Gets the Content-Type header.
  ContentType? get contentType => _response.headers.contentType;

  /// Sets the Content-Length header.
  void setContentLength(int length) {
    _response.headers.contentLength = length;
  }

  /// Gets the Content-Length header.
  int? get contentLength => _response.headers.contentLength;

  /// Sets the Cache-Control header.
  void setCacheControl(String value) {
    setHeader('Cache-Control', value);
  }

  /// Sets the Expires header.
  void setExpires(DateTime date) {
    setHeader('Expires', date.toUtc().toString());
  }

  /// Sets CORS headers.
  void setCorsHeaders({
    String? allowOrigin,
    String? allowMethods,
    String? allowHeaders,
    String? exposeHeaders,
    bool allowCredentials = false,
    int? maxAge,
  }) {
    if (allowOrigin != null) {
      setHeader('Access-Control-Allow-Origin', allowOrigin);
    }
    if (allowMethods != null) {
      setHeader('Access-Control-Allow-Methods', allowMethods);
    }
    if (allowHeaders != null) {
      setHeader('Access-Control-Allow-Headers', allowHeaders);
    }
    if (exposeHeaders != null) {
      setHeader('Access-Control-Expose-Headers', exposeHeaders);
    }
    if (allowCredentials) {
      setHeader('Access-Control-Allow-Credentials', 'true');
    }
    if (maxAge != null) {
      setHeader('Access-Control-Max-Age', maxAge.toString());
    }
  }

  /// Sets the Location header for redirects.
  void setLocation(String url) {
    setHeader('Location', url);
  }

  /// Sets common security headers.
  void setSecurityHeaders({
    bool enableHsts = false,
    bool enableCsp = false,
    bool enableXFrameOptions = true,
    bool enableXContentTypeOptions = true,
    String? cspPolicy,
  }) {
    if (enableHsts) {
      setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    }
    if (enableCsp && cspPolicy != null) {
      setHeader('Content-Security-Policy', cspPolicy);
    }
    if (enableXFrameOptions) {
      setHeader('X-Frame-Options', 'DENY');
    }
    if (enableXContentTypeOptions) {
      setHeader('X-Content-Type-Options', 'nosniff');
    }
  }

  /// Gets the raw HttpHeaders object for advanced operations.
  HttpHeaders get raw => _response.headers;
}

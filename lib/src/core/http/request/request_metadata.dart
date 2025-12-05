import 'dart:io';

/// Provides HTTP request metadata and utilities.
class RequestMetadata {
  final HttpRequest _raw;
  late final Map<String, dynamic> _metadata;

  RequestMetadata(this._raw) {
    _metadata = <String, dynamic>{};
  }

  /// Gets HTTP method.
  String get method => _raw.method;

  /// Gets request path.
  String get path => _raw.uri.path;

  /// Gets full URI.
  Uri get uri => _raw.uri;

  /// Gets query parameters.
  Map<String, String> get query => _raw.uri.queryParameters;

  /// Gets client IP address (handles proxies).
  String get ip {
    // Check for forwarded IP from proxy
    final forwarded = _raw.headers.value('x-forwarded-for');
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }

    // Check for real IP
    final realIp = _raw.headers.value('x-real-ip');
    if (realIp != null && realIp.isNotEmpty) {
      return realIp;
    }

    return _raw.connectionInfo?.remoteAddress.address ?? 'unknown';
  }

  /// Gets port.
  int? get port => _raw.connectionInfo?.remotePort;

  /// Checks if request is HTTPS.
  bool get isHttps => _raw.requestedUri.isScheme('https');

  /// Checks if request is HTTP.
  bool get isHttp => _raw.requestedUri.isScheme('http');

  /// Checks if request is secure.
  bool get isSecure => isHttps;

  /// Checks if request is AJAX/XHR.
  bool get isAjax {
    final requested = _raw.headers.value('x-requested-with');
    return requested?.toLowerCase() == 'xmlhttprequest';
  }

  /// Checks if request wants JSON.
  bool get wantsJson {
    final accept = _raw.headers.value('accept') ?? '';
    return accept.contains('application/json');
  }

  /// Gets content length.
  int? get contentLength => _raw.contentLength;

  /// Gets protocol version.
  String get protocol => '${_raw.protocolVersion}';

  /// Gets host name.
  String? get host => _raw.headers.value('host');

  /// Gets origin (for CORS).
  String? get origin => _raw.headers.value('origin');

  /// Gets referrer.
  String? get referrer => _raw.headers.value('referer');

  /// Gets user agent.
  String? get userAgent => _raw.headers.value('user-agent');

  /// Checks if request method matches.
  bool isMethod(String method) =>
      this.method.toUpperCase() == method.toUpperCase();

  /// Checks if request is GET.
  bool get isGet => isMethod('GET');

  /// Checks if request is POST.
  bool get isPost => isMethod('POST');

  /// Checks if request is PUT.
  bool get isPut => isMethod('PUT');

  /// Checks if request is PATCH.
  bool get isPatch => isMethod('PATCH');

  /// Checks if request is DELETE.
  bool get isDelete => isMethod('DELETE');

  /// Checks if request is HEAD.
  bool get isHead => isMethod('HEAD');

  /// Checks if request is OPTIONS.
  bool get isOptions => isMethod('OPTIONS');

  /// Sets custom metadata.
  void setMetadata(String key, dynamic value) {
    _metadata[key] = value;
  }

  /// Gets custom metadata.
  dynamic getMetadata(String key, [dynamic defaultValue]) {
    return _metadata[key] ?? defaultValue;
  }

  /// Gets all metadata.
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);

  /// Converts metadata to map.
  Map<String, dynamic> toMap() => {
        'method': method,
        'path': path,
        'ip': ip,
        'port': port,
        'protocol': protocol,
        'is_secure': isSecure,
        'is_ajax': isAjax,
        'wants_json': wantsJson,
        'host': host,
        'user_agent': userAgent,
        'content_length': contentLength,
      };
}

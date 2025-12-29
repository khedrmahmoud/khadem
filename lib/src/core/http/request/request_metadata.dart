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

  /// Gets a query parameter with type conversion.
  ///
  /// Supports common types: int, double, bool, String, List&lt;String&gt;.
  /// Returns null if the parameter doesn't exist or can't be converted.
  T? getQuery<T>(String key, {T? defaultValue}) {
    final value = _raw.uri.queryParameters[key];
    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    try {
      if (T == int) {
        return int.tryParse(value) as T?;
      } else if (T == double) {
        return double.tryParse(value) as T?;
      } else if (T == bool) {
        if (value.toLowerCase() == 'true' || value == '1') return true as T?;
        if (value.toLowerCase() == 'false' || value == '0') return false as T?;
        return null;
      } else if (T == String) {
        return value as T?;
      } else if (T == List<String>) {
        return value.split(',').map((s) => s.trim()).toList() as T?;
      }
    } catch (_) {
      // Return default value on parsing error
    }

    return defaultValue;
  }

  /// Gets a query parameter as integer.
  int? queryInt(String key, {int? defaultValue}) {
    return getQuery<int>(key, defaultValue: defaultValue);
  }

  /// Gets a query parameter as double.
  double? queryDouble(String key, {double? defaultValue}) {
    return getQuery<double>(key, defaultValue: defaultValue);
  }

  /// Gets a query parameter as boolean.
  ///
  /// Accepts: 'true', 'false', '1', '0' (case insensitive).
  bool? queryBool(String key, {bool? defaultValue}) {
    return getQuery<bool>(key, defaultValue: defaultValue);
  }

  /// Gets a query parameter as string.
  String? queryString(String key, {String? defaultValue}) {
    return getQuery<String>(key, defaultValue: defaultValue);
  }

  /// Gets a query parameter as list of strings.
  ///
  /// Splits by comma and trims whitespace by default.
  List<String>? queryList(String key, {String separator = ',', List<String>? defaultValue}) {
    final value = _raw.uri.queryParameters[key];
    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    try {
      return value.split(separator).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return defaultValue;
    }
  }

  /// Gets a query parameter with custom parsing function.
  T? queryWith<T>(String key, T? Function(String) parser, {T? defaultValue}) {
    final value = _raw.uri.queryParameters[key];
    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    try {
      return parser(value);
    } catch (_) {
      return defaultValue;
    }
  }

  /// Checks if a query parameter exists.
  bool hasQuery(String key) {
    return _raw.uri.queryParameters.containsKey(key);
  }

  /// Gets all query parameter keys.
  Iterable<String> get queryKeys => _raw.uri.queryParameters.keys;

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

import 'dart:io';

/// Provides efficient HTTP header access with caching.
class RequestHeaders {
  final HttpHeaders _headers;
  final Map<String, String?> _cache = {};

  RequestHeaders(this._headers);

  /// Gets a header value by name (case-insensitive).
  String? get(String name) {
    final cacheKey = name.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final value = _headers.value(name);
    _cache[cacheKey] = value;
    return value;
  }

  /// Gets all values for a header name.
  List<String>? getAll(String name) => _headers[name];

  /// Checks if a header exists.
  bool has(String name) => _headers[name] != null;

  /// Checks if multiple headers exist.
  bool hasAll(List<String> names) => names.every(has);

  /// Checks if any header exists.
  bool hasAny(List<String> names) => names.any(has);

  /// Gets Content-Type header.
  String? get contentType => get('content-type');

  /// Gets User-Agent header.
  String? get userAgent => get('user-agent');

  /// Gets Accept header.
  String? get accept => get('accept');

  /// Gets Accept-Language header.
  String? get acceptLanguage => get('accept-language');

  /// Gets Authorization header.
  String? get authorization => get('authorization');

  /// Gets X-Forwarded-For header (proxy support).
  String? get forwardedFor => get('x-forwarded-for');

  /// Gets X-Real-IP header (proxy support).
  String? get realIp => get('x-real-ip');

  /// Gets Origin header (CORS).
  String? get origin => get('origin');

  /// Gets Referer header.
  String? get referer => get('referer');

  /// Gets Host header.
  String? get host => get('host');

  /// Gets Cookie header.
  String? get cookie => get('cookie');

  /// Gets If-None-Match header (ETag).
  String? get ifNoneMatch => get('if-none-match');

  /// Gets If-Modified-Since header.
  String? get ifModifiedSince => get('if-modified-since');

  /// Gets Content-Length header as int.
  int? get contentLength {
    final value = get('content-length');
    return value != null ? int.tryParse(value) : null;
  }

  /// Gets all headers as a map.
  Map<String, String> toMap() {
    final map = <String, String>{};
    _headers.forEach((name, values) {
      if (values.isNotEmpty) {
        map[name] = values.first;
      }
    });
    return map;
  }

  /// Gets all headers as list of key-value pairs.
  List<MapEntry<String, String>> toList() {
    final list = <MapEntry<String, String>>[];
    _headers.forEach((name, values) {
      for (final value in values) {
        list.add(MapEntry(name, value));
      }
    });
    return list;
  }

  /// Checks if header matches pattern.
  bool matches(String name, Pattern pattern) {
    final value = get(name);
    return value != null && pattern.allMatches(value).isNotEmpty;
  }

  /// Clears cache.
  void clearCache() => _cache.clear();
}

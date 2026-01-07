import 'package:khadem/src/support/facades/env.dart';

/// Provides methods for generating URLs, assets, and routes.
class UrlService {
  final String _assetBaseUrl;
  final bool _forceHttps;
  final Map<String, String> _namedRoutes;

  UrlService({
    String? assetBaseUrl,
    bool forceHttps = false,
    Map<String, String>? namedRoutes,
  })  : _assetBaseUrl = assetBaseUrl ?? '',
        _forceHttps = forceHttps,
        _namedRoutes = namedRoutes ?? {};

  static String _normalizeBaseUrl(String url) {
    var normalized = url.trim();
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Generate a full URL to the given path.
  String to(String path, {Map<String, dynamic>? query}) =>
      url(path, query: query);

  /// Generate a full URL to the given path.
  String url(String path, {Map<String, dynamic>? query}) {
    final envBaseUrl = Env.get('APP_URL') ?? 'http://localhost:8080';
    final baseUrl = _normalizeBaseUrl(envBaseUrl);
    var fullUrl = '$baseUrl/${path.startsWith('/') ? path.substring(1) : path}';

    if (_forceHttps && fullUrl.startsWith('http://')) {
      fullUrl = fullUrl.replaceFirst('http://', 'https://');
    }

    if (query != null && query.isNotEmpty) {
      final queryString = _buildQueryString(query);
      fullUrl += '?$queryString';
    }

    return fullUrl;
  }

  /// Generate a secure URL (HTTPS) to the given path.
  String secure(String path, {Map<String, dynamic>? query}) {
    var secureUrl = url(path, query: query);
    if (secureUrl.startsWith('http://')) {
      secureUrl = secureUrl.replaceFirst('http://', 'https://');
    }
    return secureUrl;
  }

  /// Generate a URL to an asset.
  String asset(String path, {Map<String, dynamic>? query}) {
    final envBaseUrl = Env.get('APP_URL') ?? 'http://localhost:8080';
    final assetBase = _assetBaseUrl.isNotEmpty
        ? _assetBaseUrl
        : _normalizeBaseUrl(envBaseUrl);
    var assetUrl =
        '$assetBase/assets/${path.startsWith('/') ? path.substring(1) : path}';

    if (_forceHttps && assetUrl.startsWith('http://')) {
      assetUrl = assetUrl.replaceFirst('http://', 'https://');
    }

    if (query != null && query.isNotEmpty) {
      final queryString = _buildQueryString(query);
      assetUrl += '?$queryString';
    }

    return assetUrl;
  }

  /// Generate a URL to a CSS file.
  String css(String path, {Map<String, dynamic>? query}) {
    return asset(
      'css/${path.startsWith('/') ? path.substring(1) : path}',
      query: query,
    );
  }

  /// Generate a URL to a JavaScript file.
  String js(String path, {Map<String, dynamic>? query}) {
    return asset(
      'js/${path.startsWith('/') ? path.substring(1) : path}',
      query: query,
    );
  }

  /// Generate a URL to an image.
  String image(String path, {Map<String, dynamic>? query}) {
    return asset(
      'images/${path.startsWith('/') ? path.substring(1) : path}',
      query: query,
    );
  }

  /// Generate a URL to a file in storage.
  String storage(String path, {Map<String, dynamic>? query}) {
    var storageUrl =
        '$_assetBaseUrl/storage/${path.startsWith('/') ? path.substring(1) : path}';

    if (_forceHttps && storageUrl.startsWith('http://')) {
      storageUrl = storageUrl.replaceFirst('http://', 'https://');
    }

    if (query != null && query.isNotEmpty) {
      final queryString = _buildQueryString(query);
      storageUrl += '?$queryString';
    }

    return storageUrl;
  }

  /// Generate a URL for a named route.
  String route(
    String name, {
    Map<String, String>? parameters,
    Map<String, dynamic>? query,
  }) {
    final routePath = _namedRoutes[name];
    if (routePath == null) {
      throw ArgumentError('Route "$name" is not defined');
    }

    var url = routePath;

    // Replace route parameters
    if (parameters != null) {
      for (final entry in parameters.entries) {
        url = url.replaceAll(':${entry.key}', entry.value);
      }
    }

    // Check for missing parameters
    final missingParams = RegExp(r':(\w+)').allMatches(url);
    if (missingParams.isNotEmpty) {
      final paramNames = missingParams.map((m) => m.group(1)!).toList();
      throw ArgumentError(
        'Missing required parameters for route "$name": $paramNames',
      );
    }

    return this.url(url, query: query);
  }

  /// Check if the given URL is valid.
  bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  /// Check if the given URL is secure (HTTPS).
  bool isSecure(String url) {
    return url.startsWith('https://');
  }

  /// Get the base URL.
  String get baseUrl => Env.get('APP_URL') ?? 'http://localhost:8080';

  /// Get the asset base URL.
  String get assetBaseUrl => _assetBaseUrl;

  /// Register a named route.
  void registerRoute(String name, String path) {
    _namedRoutes[name] = path;
  }

  /// Remove a named route.
  void removeRoute(String name) {
    _namedRoutes.remove(name);
  }

  /// Get all registered route names.
  List<String> get routeNames => _namedRoutes.keys.toList();

  /// Get all named routes.
  Map<String, String> get namedRoutes => Map.unmodifiable(_namedRoutes);

  /// Check if a route is registered.
  bool hasRoute(String name) {
    return _namedRoutes.containsKey(name);
  }

  String _buildQueryString(Map<String, dynamic> query) {
    return query.entries.map((e) {
      final value = e.value;
      if (value is List) {
        return value
            .map((v) =>
                '${Uri.encodeComponent(e.key)}[]=${Uri.encodeComponent(v.toString())}',)
            .join('&');
      }
      return '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(value.toString())}';
    }).join('&');
  }
}

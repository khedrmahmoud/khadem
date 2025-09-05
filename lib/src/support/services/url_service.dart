import '../../core/storage/storage_manager.dart';

/// URL generation service similar to Laravel's URL helpers
/// Provides methods for generating URLs, assets, and routes
class UrlService {
  final String _baseUrl;
  final String _assetBaseUrl;
  final bool _forceHttps;
  final Map<String, String> _namedRoutes;

  UrlService({
    required String baseUrl,
    String? assetBaseUrl,
    bool forceHttps = false,
    Map<String, String>? namedRoutes,
  })  : _baseUrl = _normalizeBaseUrl(baseUrl),
        _assetBaseUrl = assetBaseUrl ?? _normalizeBaseUrl(baseUrl),
        _forceHttps = forceHttps,
        _namedRoutes = namedRoutes ?? {};

  static String _normalizeBaseUrl(String url) {
    var normalized = url.trim();
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Generate a full URL to the given path
  String url(String path, {Map<String, String>? query}) {
    var fullUrl = '$_baseUrl/${path.startsWith('/') ? path.substring(1) : path}';

    if (_forceHttps && fullUrl.startsWith('http://')) {
      fullUrl = fullUrl.replaceFirst('http://', 'https://');
    }

    if (query != null && query.isNotEmpty) {
      final queryString = _buildQueryString(query);
      fullUrl += '?$queryString';
    }

    return fullUrl;
  }

  /// Generate a URL to an asset
  String asset(String path, {Map<String, String>? query}) {
    var assetUrl = '$_assetBaseUrl/assets/${path.startsWith('/') ? path.substring(1) : path}';

    if (_forceHttps && assetUrl.startsWith('http://')) {
      assetUrl = assetUrl.replaceFirst('http://', 'https://');
    }

    if (query != null && query.isNotEmpty) {
      final queryString = _buildQueryString(query);
      assetUrl += '?$queryString';
    }

    return assetUrl;
  }

  /// Generate a URL to a CSS file
  String css(String path, {Map<String, String>? query}) {
    return asset('css/${path.startsWith('/') ? path.substring(1) : path}', query: query);
  }

  /// Generate a URL to a JavaScript file
  String js(String path, {Map<String, String>? query}) {
    return asset('js/${path.startsWith('/') ? path.substring(1) : path}', query: query);
  }

  /// Generate a URL to an image
  String image(String path, {Map<String, String>? query}) {
    return asset('images/${path.startsWith('/') ? path.substring(1) : path}', query: query);
  }

  /// Generate a URL to a file in storage
  String storage(String path, {Map<String, String>? query}) {
    var storageUrl = '$_assetBaseUrl/storage/${path.startsWith('/') ? path.substring(1) : path}';

    if (_forceHttps && storageUrl.startsWith('http://')) {
      storageUrl = storageUrl.replaceFirst('http://', 'https://');
    }

    if (query != null && query.isNotEmpty) {
      final queryString = _buildQueryString(query);
      storageUrl += '?$queryString';
    }

    return storageUrl;
  }

  /// Generate a URL for a named route
  String route(String name, {Map<String, String>? parameters, Map<String, String>? query}) {
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
      throw ArgumentError('Missing required parameters for route "$name": $paramNames');
    }

    return this.url(url, query: query);
  }

  /// Generate a secure URL (HTTPS)
  String secure(String path, {Map<String, String>? query}) {
    var secureUrl = url(path, query: query);
    if (secureUrl.startsWith('http://')) {
      secureUrl = secureUrl.replaceFirst('http://', 'https://');
    }
    return secureUrl;
  }

  /// Generate a URL to the previous page
  String previous({String fallback = '/'}) {
    // In a real implementation, this would get the previous URL from the session/request
    // For now, return the fallback
    return url(fallback);
  }

  /// Check if the given URL is valid
  bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  /// Get the base URL
  String get baseUrl => _baseUrl;

  /// Get the asset base URL
  String get assetBaseUrl => _assetBaseUrl;

  /// Register a named route
  void registerRoute(String name, String path) {
    _namedRoutes[name] = path;
  }

  /// Remove a named route
  void removeRoute(String name) {
    _namedRoutes.remove(name);
  }

  /// Get all registered route names
  List<String> get routeNames => _namedRoutes.keys.toList();

  /// Get all named routes
  Map<String, String> get namedRoutes => Map.unmodifiable(_namedRoutes);

  /// Check if a route is registered
  bool hasRoute(String name) {
    return _namedRoutes.containsKey(name);
  }

  String _buildQueryString(Map<String, String> query) {
    return query.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

/// Asset service for managing static assets and files
class AssetService {
  final UrlService _urlService;
  final StorageManager _storageManager;

  AssetService(this._urlService, this._storageManager);

  /// Get URL for an asset
  String asset(String path, {Map<String, String>? query}) {
    return _urlService.asset(path, query: query);
  }

  /// Get URL for a CSS file
  String css(String path, {Map<String, String>? query}) {
    return _urlService.css(path, query: query);
  }

  /// Get URL for a JavaScript file
  String js(String path, {Map<String, String>? query}) {
    return _urlService.js(path, query: query);
  }

  /// Get URL for an image
  String image(String path, {Map<String, String>? query}) {
    return _urlService.image(path, query: query);
  }

  /// Get URL for a file in storage
  String storage(String path, {Map<String, String>? query}) {
    return _urlService.storage(path, query: query);
  }

  /// Store a file and return its URL
  Future<String> storeFile(
    String path,
    List<int> bytes, {
    String disk = 'public',
    String? filename,
  }) async {
    final storage = _storageManager.disk(disk);
    final finalPath = filename ?? path;

    await storage.put(finalPath, bytes);
    return finalPath;
  }

  /// Store a text file and return its URL
  Future<String> storeTextFile(
    String path,
    String content, {
    String disk = 'public',
    String? filename,
  }) async {
    final storage = _storageManager.disk(disk);
    final finalPath = filename ?? path;

    await storage.writeString(finalPath, content);
    return storage.url(finalPath);
  }

  /// Delete a stored file
  Future<void> deleteFile(String path, {String disk = 'public'}) async {
    final storage = _storageManager.disk(disk);
    await storage.delete(path);
  }

  /// Check if a file exists
  Future<bool> fileExists(String path, {String disk = 'public'}) async {
    final storage = _storageManager.disk(disk);
    return storage.exists(path);
  }

  /// Get file size
  Future<int> fileSize(String path, {String disk = 'public'}) async {
    final storage = _storageManager.disk(disk);
    return storage.size(path);
  }

  /// Copy a file
  Future<void> copyFile(
    String from,
    String to, {
    String disk = 'public',
  }) async {
    final storage = _storageManager.disk(disk);
    await storage.copy(from, to);
  }

  /// Move a file
  Future<void> moveFile(
    String from,
    String to, {
    String disk = 'public',
  }) async {
    final storage = _storageManager.disk(disk);
    await storage.move(from, to);
  }

  /// List files in a directory
  Future<List<String>> listFiles(
    String directory, {
    String disk = 'public',
  }) async {
    final storage = _storageManager.disk(disk);
    return storage.listFiles(directory);
  }

  /// Generate a unique filename
  String generateUniqueFilename(String originalFilename) {
    final extension = originalFilename.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return '${timestamp}_$random.$extension';
  }

  /// Validate file type
  bool isValidFileType(String filename, List<String> allowedExtensions) {
    final extension = filename.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Get file extension
  String getFileExtension(String filename) {
    return filename.split('.').last;
  }

  /// Get file name without extension
  String getFileNameWithoutExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.sublist(0, parts.length - 1).join('.') : filename;
  }
}

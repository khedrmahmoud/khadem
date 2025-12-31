import '../../../core/storage/storage_manager.dart';
import 'url_service.dart';

/// Asset service for managing static assets and files.
class AssetService {
  final UrlService _urlService;
  final StorageManager _storageManager;

  AssetService(this._urlService, this._storageManager);

  /// Get URL for an asset.
  String url(String path, {Map<String, dynamic>? query}) {
    return _urlService.asset(path, query: query);
  }

  /// Get URL for an asset (alias).
  String asset(String path, {Map<String, dynamic>? query}) {
    return _urlService.asset(path, query: query);
  }

  /// Get URL for a CSS file.
  String css(String path, {Map<String, dynamic>? query}) {
    return _urlService.css(path, query: query);
  }

  /// Get URL for a JavaScript file.
  String js(String path, {Map<String, dynamic>? query}) {
    return _urlService.js(path, query: query);
  }

  /// Get URL for an image.
  String image(String path, {Map<String, dynamic>? query}) {
    return _urlService.image(path, query: query);
  }

  /// Get URL for a file in storage.
  String storage(String path, {Map<String, dynamic>? query}) {
    return _urlService.storage(path, query: query);
  }

  /// Store a file and return its URL.
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

  /// Store a text file and return its URL.
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

  /// Delete a stored file.
  Future<void> deleteFile(String path, {String disk = 'public'}) async {
    final storage = _storageManager.disk(disk);
    await storage.delete(path);
  }

  /// Check if a file exists.
  Future<bool> fileExists(String path, {String disk = 'public'}) async {
    final storage = _storageManager.disk(disk);
    return storage.exists(path);
  }

  /// Get file size.
  Future<int> fileSize(String path, {String disk = 'public'}) async {
    final storage = _storageManager.disk(disk);
    return storage.size(path);
  }

  /// Get file MIME type.
  Future<String?> mimeType(String path, {String disk = 'public'}) async {
    final storage = _storageManager.disk(disk);
    return storage.mimeType(path);
  }

  /// Copy a file.
  Future<void> copyFile(
    String from,
    String to, {
    String disk = 'public',
  }) async {
    final storage = _storageManager.disk(disk);
    await storage.copy(from, to);
  }

  /// Move a file.
  Future<void> moveFile(
    String from,
    String to, {
    String disk = 'public',
  }) async {
    final storage = _storageManager.disk(disk);
    await storage.move(from, to);
  }

  /// List files in a directory.
  Future<List<String>> listFiles(
    String directory, {
    String disk = 'public',
  }) async {
    final storage = _storageManager.disk(disk);
    return storage.listFiles(directory);
  }

  /// Generate a unique filename.
  String generateUniqueFilename(String originalFilename) {
    final extension = originalFilename.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return '${timestamp}_$random.$extension';
  }

  /// Validate file type.
  bool isValidFileType(String filename, List<String> allowedExtensions) {
    final extension = filename.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Get file extension.
  String getFileExtension(String filename) {
    return filename.split('.').last;
  }

  /// Get file name without extension.
  String getFileNameWithoutExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1
        ? parts.sublist(0, parts.length - 1).join('.')
        : filename;
  }
}

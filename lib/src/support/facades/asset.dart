/// Facade for asset helpers and storage-backed asset operations.
///
/// Use `Asset.url`, `Asset.storeFile`, and related helpers to manage
/// assets without resolving the underlying `AssetService`.
import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/support/services/url/asset_service.dart';

/// Facade for asset-related helpers and storage-backed asset operations.
class Asset {
  static AssetService get _instance => Khadem.make<AssetService>();

  static String url(String path, {Map<String, dynamic>? query}) =>
      _instance.url(path, query: query);

  static String asset(String path, {Map<String, dynamic>? query}) =>
      _instance.asset(path, query: query);

  static String css(String path, {Map<String, dynamic>? query}) =>
      _instance.css(path, query: query);

  static String js(String path, {Map<String, dynamic>? query}) =>
      _instance.js(path, query: query);

  static String image(String path, {Map<String, dynamic>? query}) =>
      _instance.image(path, query: query);

  static String storage(String path, {Map<String, dynamic>? query}) =>
      _instance.storage(path, query: query);

  static Future<String> storeFile(
          String path, List<int> bytes,
          {String disk = 'public', String? filename}) =>
      _instance.storeFile(path, bytes, disk: disk, filename: filename);

  static Future<String> storeTextFile(String path, String content,
          {String disk = 'public', String? filename}) =>
      _instance.storeTextFile(path, content, disk: disk, filename: filename);

  static Future<void> deleteFile(String path, {String disk = 'public'}) =>
      _instance.deleteFile(path, disk: disk);

  static Future<bool> fileExists(String path, {String disk = 'public'}) =>
      _instance.fileExists(path, disk: disk);

  static Future<int> fileSize(String path, {String disk = 'public'}) =>
      _instance.fileSize(path, disk: disk);

  static Future<String?> mimeType(String path, {String disk = 'public'}) =>
      _instance.mimeType(path, disk: disk);

  static Future<void> copyFile(String from, String to, {String disk = 'public'}) =>
      _instance.copyFile(from, to, disk: disk);

  static Future<void> moveFile(String from, String to, {String disk = 'public'}) =>
      _instance.moveFile(from, to, disk: disk);

  static Future<List<String>> listFiles(String directory, {String disk = 'public'}) =>
      _instance.listFiles(directory, disk: disk);

  static String generateUniqueFilename(String originalFilename) =>
      _instance.generateUniqueFilename(originalFilename);

  static bool isValidFileType(String filename, List<String> allowedExtensions) =>
      _instance.isValidFileType(filename, allowedExtensions);

  static String getFileExtension(String filename) =>
      _instance.getFileExtension(filename);

  static String getFileNameWithoutExtension(String filename) =>
      _instance.getFileNameWithoutExtension(filename);
}

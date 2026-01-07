import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/contracts/storage/storage_disk.dart';
import 'package:khadem/src/core/storage/storage_manager.dart';

/// Facade for the storage system.
///
/// Provides convenient static access to storage operations (put/get/copy/etc.)
/// and a short-hand to the default or named disks. Use `Storage.put(...)`,
/// `Storage.disk('s3')`, or `Storage.temporaryUrl(...)` from anywhere.
class Storage {
  static StorageManager get _instance => Khadem.make<StorageManager>();

  /// Returns a disk instance by name or uses the default.
  static StorageDisk disk([String? name]) => _instance.disk(name);

  static Future<void> put(String path, List<int> bytes) =>
      _instance.put(path, bytes);

  static Future<void> writeString(String path, String content) =>
      _instance.writeString(path, content);

  static Future<String> readString(String path) => _instance.readString(path);

  static Future<List<int>> get(String path) => _instance.get(path);

  static Stream<List<int>> getStream(String path) => _instance.getStream(path);

  static Future<void> putStream(String path, Stream<List<int>> stream) =>
      _instance.putStream(path, stream);

  static Future<void> delete(String path) => _instance.delete(path);

  static Future<bool> exists(String path) => _instance.exists(path);

  static Future<String?> mimeType(String path) => _instance.mimeType(path);

  static Future<int> size(String path) => _instance.size(path);

  static Future<DateTime> lastModified(String path) =>
      _instance.lastModified(path);

  static Future<void> copy(String from, String to) => _instance.copy(from, to);

  static Future<void> move(String from, String to) => _instance.move(from, to);

  static String url(String path) => _instance.url(path);

  static Future<String> temporaryUrl(String path, DateTime expiration) =>
      _instance.temporaryUrl(path, expiration);

  static Future<void> makeDirectory(String path) =>
      _instance.makeDirectory(path);

  static Future<void> deleteDirectory(String path) =>
      _instance.deleteDirectory(path);

  static Future<List<String>> listFiles(String directoryPath) =>
      _instance.listFiles(directoryPath);
}

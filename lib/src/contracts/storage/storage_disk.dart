/// A simple contract for a file storage system.
///
/// This contract is a base for all file storage systems. It provides a
/// simple and easy-to-use interface for saving and retrieving files from
/// the disk or remote sources.
abstract class StorageDisk {
  /// Saves the given bytes to the given path on the disk.
  Future<void> put(String path, List<int> bytes);

  /// Writes a string directly to a file.
  Future<void> writeString(String path, String content);

  /// Reads a string from a file.
  Future<String> readString(String path);

  /// Retrieves the bytes saved at the given path on the disk.
  Future<List<int>> get(String path);

  /// Deletes the file saved at the given path on the disk.
  Future<void> delete(String path);

  /// Checks if the file exists at the given path.
  Future<bool> exists(String path);

  /// Copies the file from one path to another.
  Future<void> copy(String from, String to);

  /// Moves the file from one path to another.
  Future<void> move(String from, String to);

  /// Returns the size of the file in bytes.
  Future<int> size(String path);

  /// Returns the last modified time of the file.
  Future<DateTime> lastModified(String path);

  /// Lists files under the specified directory.
  Future<List<String>> listFiles(String directoryPath);

  /// Returns the full URL or public path to the file.
  String url(String path);
}

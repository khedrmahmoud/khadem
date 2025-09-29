import 'dart:convert';
import 'dart:io';

/// Session Storage Interface
/// Defines the contract for session storage implementations
abstract class SessionStorage {
  /// Store session data
  Future<void> write(String sessionId, Map<String, dynamic> data);

  /// Retrieve session data
  Future<Map<String, dynamic>?> read(String sessionId);

  /// Delete session data
  Future<void> delete(String sessionId);

  /// Clean up expired sessions
  Future<void> cleanup(Duration maxAge);
}

/// File-based Session Storage Implementation
class FileSessionStorage implements SessionStorage {
  final Directory _directory;

  FileSessionStorage(String path)
      : _directory = Directory(path) {
    if (!_directory.existsSync()) {
      _directory.createSync(recursive: true);
    }
  }

  @override
  Future<void> write(String sessionId, Map<String, dynamic> data) async {
    final file = File('${_directory.path}/$sessionId.session');
    final jsonData = jsonEncode(data);
    await file.writeAsString(jsonData);
  }

  @override
  Future<Map<String, dynamic>?> read(String sessionId) async {
    final file = File('${_directory.path}/$sessionId.session');
    if (!await file.exists()) {
      return null;
    }

    try {
      final jsonData = await file.readAsString();
      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      // Invalid session file, remove it
      await file.delete();
      return null;
    }
  }

  @override
  Future<void> delete(String sessionId) async {
    final file = File('${_directory.path}/$sessionId.session');
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> cleanup(Duration maxAge) async {
    if (!await _directory.exists()) return;

    final files = _directory.listSync();
    final now = DateTime.now();

    for (final file in files) {
      if (file is File && file.path.endsWith('.session')) {
        try {
          final stat = await file.stat();
          if (now.difference(stat.modified) > maxAge) {
            await file.delete();
          }
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    }
  }
}
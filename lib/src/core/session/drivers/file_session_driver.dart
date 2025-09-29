import 'dart:convert';
import 'dart:io';
import '../../../contracts/session/session_interfaces.dart';

/// File-based session storage implementation.
/// Stores session data in JSON files on disk.
class FileSessionDriver implements SessionDriver {
  final Directory _directory;

  FileSessionDriver(String path)
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

  @override
  Future<bool> isConnected() async {
    try {
      await _directory.stat();
      return true;
    } catch (e) {
      return false;
    }
  }
}
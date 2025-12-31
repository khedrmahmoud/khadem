import 'dart:io';

import '../../contracts/storage/storage_disk.dart';

class LocalDisk implements StorageDisk {
  final String basePath;

  LocalDisk({required this.basePath});

  File _file(String path) => File('$basePath/$path');

  @override
  Future<void> put(String path, List<int> bytes) async {
    final file = _file(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  @override
  Future<void> writeString(String path, String content) async {
    final file = _file(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  Future<String> readString(String path) async {
    final file = _file(path);
    return file.readAsString();
  }

  @override
  Future<List<int>> get(String path) async {
    final file = _file(path);
    return file.readAsBytes();
  }

  @override
  Stream<List<int>> getStream(String path) {
    final file = _file(path);
    return file.openRead();
  }

  @override
  Future<void> putStream(String path, Stream<List<int>> stream) async {
    final file = _file(path);
    await file.create(recursive: true);
    final sink = file.openWrite();
    await sink.addStream(stream);
    await sink.close();
  }

  @override
  Future<void> delete(String path) async {
    final file = _file(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> makeDirectory(String path) async {
    final dir = Directory('$basePath/$path');
    await dir.create(recursive: true);
  }

  @override
  Future<void> deleteDirectory(String path) async {
    final dir = Directory('$basePath/$path');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<bool> exists(String path) async {
    return _file(path).exists();
  }

  @override
  Future<String?> mimeType(String path) async {
    // Basic extension-based mime type detection
    final ext = path.split('.').last.toLowerCase();
    const mimes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'json': 'application/json',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      'zip': 'application/zip',
    };
    return mimes[ext];
  }

  @override
  Future<void> copy(String from, String to) async {
    final src = _file(from);
    final dst = _file(to);
    await dst.create(recursive: true);
    await src.copy(dst.path);
  }

  @override
  Future<void> move(String from, String to) async {
    final src = _file(from);
    final dst = _file(to);
    await dst.create(recursive: true);
    await src.rename(dst.path);
  }

  @override
  Future<int> size(String path) async {
    final file = _file(path);
    final stat = await file.stat();
    return stat.size;
  }

  @override
  Future<DateTime> lastModified(String path) async {
    final file = _file(path);
    return file.lastModified();
  }

  @override
  Future<List<String>> listFiles(String directoryPath) async {
    final dir = Directory('$basePath/$directoryPath');
    if (!await dir.exists()) return [];
    return dir
        .list()
        .where((e) => e is File)
        .map((e) => e.path.replaceFirst('$basePath/', ''))
        .toList();
  }

  @override
  String url(String path) {
    final file = _file(path);
    return file.resolveSymbolicLinksSync();
  }

  @override
  Future<String> temporaryUrl(String path, DateTime expiration) async {
    return url(path);
  }
}

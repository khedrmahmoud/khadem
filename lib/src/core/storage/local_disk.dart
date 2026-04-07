import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../contracts/storage/storage_disk.dart';

class LocalDisk implements StorageDisk {
  final String basePath;
  final String _resolvedBasePath;

  LocalDisk({required this.basePath})
    : _resolvedBasePath = p.normalize(p.absolute(basePath));

  File _file(String path) => File(_resolvePath(path));

  Directory _directory(String path) =>
      Directory(_resolvePath(path, allowBaseDirectory: true));

  String _resolvePath(String relativePath, {bool allowBaseDirectory = false}) {
    final normalizedInput = relativePath.trim().replaceAll('\\', '/');

    if (normalizedInput.isEmpty) {
      if (allowBaseDirectory) {
        return _resolvedBasePath;
      }
      throw ArgumentError('Path cannot be empty');
    }

    if (p.isAbsolute(normalizedInput)) {
      throw ArgumentError('Absolute paths are not allowed: $relativePath');
    }

    final resolved = p.normalize(
      p.absolute(p.join(_resolvedBasePath, normalizedInput)),
    );

    if (resolved != _resolvedBasePath &&
        !p.isWithin(_resolvedBasePath, resolved)) {
      throw ArgumentError('Path traversal detected: $relativePath');
    }

    return resolved;
  }

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
    final dir = _directory(path);
    await dir.create(recursive: true);
  }

  @override
  Future<void> deleteDirectory(String path) async {
    final dir = _directory(path);
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
    return lookupMimeType(path);
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
    final dir = _directory(directoryPath);
    if (!await dir.exists()) return [];
    return dir
        .list()
        .where((e) => e is File)
        .map(
          (e) =>
              p.relative(e.path, from: _resolvedBasePath).replaceAll('\\', '/'),
        )
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

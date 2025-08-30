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
  Future<void> delete(String path) async {
    final file = _file(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> exists(String path) async {
    return _file(path).exists();
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
    return 'file://$basePath/$path';
  }
}

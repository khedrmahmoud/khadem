// file_cache_driver.dart
import 'dart:convert';
import 'dart:io';
import '../../contracts/cache/cache_driver.dart';

class FileCacheDriver implements CacheDriver {
  late final String _cacheDir;

  FileCacheDriver({Map<String, dynamic>? config}) {
    _cacheDir = (config?['path'] as String?) ?? 'storage/cache';
    Directory(_cacheDir).createSync(recursive: true);
  }

  @override
  Future<void> put(String key, dynamic value, Duration ttl) async {
    final file = File('$_cacheDir/$key.json');
    final data = {
      'value': value,
      'expires_at': DateTime.now().add(ttl).toIso8601String(),
      'ttl': ttl.inSeconds,
    };
    await file.writeAsString(jsonEncode(data));
  }

  @override
  Future<dynamic> get(String key) async {
    final file = File('$_cacheDir/$key.json');
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString());
    final expiresAt = DateTime.parse(data['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) {
      await forget(key);
      return null;
    }
    return data['value'];
  }

  @override
  Future<void> forget(String key) async {
    final file = File('$_cacheDir/$key.json');
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> clear() async {
    final dir = Directory(_cacheDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  @override
  Future<bool> has(String key) async {
    return await get(key) != null;
  }
}

// hybrid_cache_driver.dart
import '../../contracts/cache/cache_driver.dart';
import 'file_cache_driver.dart';
import 'memory_cache_driver.dart';

class HybridCacheDriver implements CacheDriver {
  final MemoryCacheDriver memory = MemoryCacheDriver();
  final FileCacheDriver file;
  // Optional: RedisCacheDriver redis;

  HybridCacheDriver({required String filePath})
      : file = FileCacheDriver(config: {'path': filePath});

  @override
  Future<void> put(String key, dynamic value, Duration ttl) async {
    await memory.put(key, value, ttl);
    await file.put(key, value, ttl);
  }

  @override
  Future<dynamic> get(String key) async {
    final mem = await memory.get(key);
    if (mem != null) return mem;

    final fromFile = await file.get(key);
    if (fromFile != null) {
      await memory.put(key, fromFile, const Duration(seconds: 30));
    }
    return fromFile;
  }

  @override
  Future<void> forget(String key) async {
    await memory.forget(key);
    await file.forget(key);
  }

  @override
  Future<bool> has(String key) async {
    return await memory.has(key) || await file.has(key);
  }

  @override
  Future<void> clear() async {
    await memory.clear();
    await file.clear();
  }
}

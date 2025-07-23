import '../../contracts/cache/cache_driver.dart';

class MemoryCacheDriver implements CacheDriver {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<void> put(String key, dynamic value, Duration ttl) async {
    _store[key] = {
      'value': value,
      'ttl': ttl.inSeconds,
      'expires_at': DateTime.now().add(ttl).toIso8601String(),
    };
  }

  @override
  Future<dynamic> get(String key) async {
    final data = _store[key];
    if (data == null) return null;
    if (DateTime.parse(data['expires_at']).isBefore(DateTime.now())) {
      await forget(key);
      return null;
    }
    return data['value'];
  }

  @override
  Future<void> forget(String key) async => _store.remove(key);

  @override
  Future<bool> has(String key) async => await get(key) != null;

  @override
  Future<void> clear() async => _store.clear();
}

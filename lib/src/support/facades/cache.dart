import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/contracts/cache/cache_driver.dart';
import 'package:khadem/src/contracts/cache/cache_manager_contract.dart';
import 'package:khadem/src/core/cache/cache_stats.dart';

/// Facade for the cache system.
///
/// Provides convenient synchronous/static access to the application's cache
/// manager. Use `Cache.put`, `Cache.get`, etc. from anywhere in the codebase.
class Cache {
  static ICacheManager get _instance => Khadem.make<ICacheManager>();

  static Future<void> put(String key, dynamic value, Duration ttl) =>
      _instance.put(key, value, ttl);

  static Future<bool> add(String key, dynamic value, Duration ttl) =>
      _instance.add(key, value, ttl);

  static Future<dynamic> get(String key) => _instance.get(key);

  static Future<Map<String, dynamic>> many(List<String> keys) =>
      _instance.many(keys);

  static Future<void> putMany(Map<String, dynamic> values, Duration ttl) =>
      _instance.putMany(values, ttl);

  static Future<int> increment(String key, [int amount = 1]) =>
      _instance.increment(key, amount);

  static Future<int> decrement(String key, [int amount = 1]) =>
      _instance.decrement(key, amount);

  static Future<dynamic> pull(String key) => _instance.pull(key);

  static Future<void> forget(String key) => _instance.forget(key);

  static Future<bool> has(String key) => _instance.has(key);

  static Future<void> clear() => _instance.clear();

  static Future<void> forever(String key, dynamic value) =>
      _instance.forever(key, value);

  static Future<dynamic> remember(
    String key,
    Duration ttl,
    Future<dynamic> Function() callback,
  ) =>
      _instance.remember(key, ttl, callback);

  static Future<void> tag(String key, List<String> tags) =>
      _instance.tag(key, tags);

  static Future<void> forgetByTag(String tag) => _instance.forgetByTag(tag);

  static CacheDriver store(String name) => _instance.store(name);

  static CacheDriver driver([String? name]) => _instance.driver(name);

  static CacheStats get stats => _instance.stats;
}

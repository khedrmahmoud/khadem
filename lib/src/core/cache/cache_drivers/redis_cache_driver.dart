// redis_cache_driver.dart
import 'dart:convert';
import 'package:redis/redis.dart';
import '../../../contracts/cache/cache_driver.dart';

class RedisCacheDriver implements CacheDriver {
  final String host;
  final int port;

  RedisCacheDriver({this.host = 'localhost', this.port = 6379});

  Future<Command> _connect() async {
    final conn = RedisConnection();
    return conn.connect(host, port);
  }

  @override
  Future<void> put(String key, dynamic value, Duration ttl) async {
    final command = await _connect();
    await command.send_object(['SET', key, jsonEncode(value), 'EX', ttl.inSeconds]);
  }

  @override
  Future<dynamic> get(String key) async {
    final command = await _connect();
    final result = await command.send_object(['GET', key]);
    return result != null ? jsonDecode(result) : null;
  }

  @override
  Future<void> forget(String key) async {
    final command = await _connect();
    await command.send_object(['DEL', key]);
  }

  @override
  Future<bool> has(String key) async {
    final command = await _connect();
    final result = await command.send_object(['EXISTS', key]);
    return result == 1;
  }

  @override
  Future<void> clear() async {
    final command = await _connect();
    await command.send_object(['FLUSHDB']);
  }
}

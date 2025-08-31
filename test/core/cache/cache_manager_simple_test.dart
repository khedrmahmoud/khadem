import 'dart:io';

import 'package:khadem/src/core/cache/cache_manager.dart';
import 'package:khadem/src/support/cache_drivers/memory_cache_driver.dart';
import 'package:khadem/src/support/exceptions/cache_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('CacheManager', () {
    late CacheManager cacheManager;
    late MemoryCacheDriver memoryDriver;

    setUp(() {
      cacheManager = CacheManager();
      memoryDriver = MemoryCacheDriver();
    });

    tearDown(() {
      // Clean up any test files
      final testCacheDir = Directory('./test_cache');
      if (testCacheDir.existsSync()) {
        testCacheDir.deleteSync(recursive: true);
      }
    });

    test('should initialize with no drivers', () {
      expect(cacheManager.driverNames, isEmpty);
      expect(() => cacheManager.defaultDriverName, throwsA(isA<CacheException>()));
    });

    test('should register driver successfully', () {
      cacheManager.registerDriver('memory', memoryDriver);

      expect(cacheManager.driverNames, contains('memory'));
      expect(cacheManager.defaultDriverName, equals('memory'));
    });

    test('should throw when registering driver with empty name', () {
      expect(() => cacheManager.registerDriver('', memoryDriver),
             throwsA(isA<CacheException>()));
    });

    test('should throw when registering duplicate driver', () {
      cacheManager.registerDriver('memory', memoryDriver);
      expect(() => cacheManager.registerDriver('memory', memoryDriver),
             throwsA(isA<CacheException>()));
    });

    test('should set default driver successfully', () {
      final driver1 = MemoryCacheDriver();
      final driver2 = MemoryCacheDriver();

      cacheManager.registerDriver('driver1', driver1);
      cacheManager.registerDriver('driver2', driver2);

      cacheManager.setDefaultDriver('driver2');
      expect(cacheManager.defaultDriverName, equals('driver2'));
    });

    test('should throw when setting non-existent driver as default', () {
      expect(() => cacheManager.setDefaultDriver('nonexistent'),
             throwsA(isA<CacheException>()));
    });

    test('should get specific driver', () {
      final driver1 = MemoryCacheDriver();
      final driver2 = MemoryCacheDriver();

      cacheManager.registerDriver('driver1', driver1);
      cacheManager.registerDriver('driver2', driver2);

      expect(cacheManager.driver('driver1'), equals(driver1));
      expect(cacheManager.driver('driver2'), equals(driver2));
    });

    test('should throw when getting non-existent driver', () {
      expect(() => cacheManager.driver('nonexistent'),
             throwsA(isA<CacheException>()));
    });

    test('should get default driver when no name provided', () {
      cacheManager.registerDriver('memory', memoryDriver);
      expect(cacheManager.driver(), equals(memoryDriver));
    });

    test('should put and get value successfully', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      await cacheManager.put('key', 'value', Duration(minutes: 5));
      final result = await cacheManager.get('key');

      expect(result, equals('value'));
    });

    test('should throw when putting with empty key', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      expect(() => cacheManager.put('', 'value', Duration(minutes: 5)),
             throwsA(isA<CacheException>()));
    });

    test('should throw when getting with empty key', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      expect(() => cacheManager.get(''),
             throwsA(isA<CacheException>()));
    });

    test('should forget value successfully', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      await cacheManager.put('key', 'value', Duration(minutes: 5));
      expect(await cacheManager.has('key'), isTrue);

      await cacheManager.forget('key');
      expect(await cacheManager.has('key'), isFalse);
    });

    test('should throw when forgetting with empty key', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      expect(() => cacheManager.forget(''),
             throwsA(isA<CacheException>()));
    });

    test('should check if key exists', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      expect(await cacheManager.has('nonexistent'), isFalse);

      await cacheManager.put('key', 'value', Duration(minutes: 5));
      expect(await cacheManager.has('key'), isTrue);
    });

    test('should throw when checking with empty key', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      expect(() => cacheManager.has(''),
             throwsA(isA<CacheException>()));
    });

    test('should clear cache successfully', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      await cacheManager.put('key1', 'value1', Duration(minutes: 5));
      await cacheManager.put('key2', 'value2', Duration(minutes: 5));

      expect(await cacheManager.has('key1'), isTrue);
      expect(await cacheManager.has('key2'), isTrue);

      await cacheManager.clear();

      expect(await cacheManager.has('key1'), isFalse);
      expect(await cacheManager.has('key2'), isFalse);
    });

    test('should remember pattern work when cache miss', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      final result = await cacheManager.remember('key', Duration(minutes: 5),
          () async => 'computed_value');

      expect(result, equals('computed_value'));

      // Should be cached now
      final cachedResult = await cacheManager.get('key');
      expect(cachedResult, equals('computed_value'));
    });

    test('should remember pattern work when cache hit', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      await cacheManager.put('key', 'cached_value', Duration(minutes: 5));

      final result = await cacheManager.remember('key', Duration(minutes: 5),
          () async => 'computed_value');

      expect(result, equals('cached_value'));
    });

    test('should tag cache items', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      await cacheManager.tag('key1', ['tag1', 'tag2']);
      await cacheManager.tag('key2', ['tag1']);

      // Tags are stored internally but don't affect functionality directly
      expect(cacheManager.stats.puts, equals(0)); // No actual puts happened
    });

    test('should forget by tag', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      await cacheManager.put('key1', 'value1', Duration(minutes: 5));
      await cacheManager.put('key2', 'value2', Duration(minutes: 5));

      await cacheManager.tag('key1', ['tag1']);
      await cacheManager.tag('key2', ['tag1']);

      expect(await cacheManager.has('key1'), isTrue);
      expect(await cacheManager.has('key2'), isTrue);

      await cacheManager.forgetByTag('tag1');

      expect(await cacheManager.has('key1'), isFalse);
      expect(await cacheManager.has('key2'), isFalse);
    });

    test('should track cache statistics', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      await cacheManager.put('key', 'value', Duration(minutes: 5));
      await cacheManager.get('key');
      await cacheManager.has('key');

      final stats = cacheManager.stats;
      expect(stats.puts, equals(1));
      expect(stats.hits, equals(2)); // get and has both hit
      expect(stats.misses, equals(0));
    });

    test('should calculate hit rate correctly', () async {
      cacheManager.registerDriver('memory', memoryDriver);

      await cacheManager.get('hit'); // miss
      await cacheManager.put('hit', 'value', Duration(minutes: 5));
      await cacheManager.get('hit'); // hit

      final stats = cacheManager.stats;
      expect(stats.hitRate, equals(0.5));
    });
  });
}

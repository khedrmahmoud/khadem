import 'package:test/test.dart';

import '../../../lib/src/contracts/cache/cache_config_loader.dart';
import '../../../lib/src/contracts/cache/cache_driver_registry.dart';
import '../../../lib/src/contracts/cache/cache_statistics_manager.dart';
import '../../../lib/src/contracts/cache/cache_tag_manager.dart';
import '../../../lib/src/contracts/cache/cache_validator.dart';
import '../../../lib/src/core/cache/cache_drivers/memory_cache_driver.dart';
import '../../../lib/src/core/cache/config/cache_config_loader.dart';
import '../../../lib/src/core/cache/managers/cache_driver_registry.dart';
import '../../../lib/src/core/cache/managers/cache_manager.dart';
import '../../../lib/src/core/cache/managers/cache_statistics_manager.dart';
import '../../../lib/src/core/cache/managers/cache_tag_manager.dart';
import '../../../lib/src/core/cache/managers/cache_validator.dart';

void main() {
  group('CacheManager Modular Architecture', () {
    late ICacheDriverRegistry driverRegistry;
    late ICacheStatisticsManager statisticsManager;
    late ICacheTagManager tagManager;
    late ICacheValidator validator;
    late ICacheConfigLoader configLoader;
    late CacheManager cacheManager;

    setUp(() {
      // Initialize all managers
      driverRegistry = CacheDriverRegistry();
      statisticsManager = CacheStatisticsManager();
      tagManager = CacheTagManager();
      validator = CacheValidator();
      configLoader = CacheConfigLoader();

      // Create cache manager with dependency injection
      cacheManager = CacheManager(
        driverRegistry: driverRegistry,
        statisticsManager: statisticsManager,
        tagManager: tagManager,
        configLoader: configLoader,
        validator: validator,
      );

      // Register a memory driver for testing
      cacheManager.registerDriver('memory', MemoryCacheDriver());
      cacheManager.setDefaultDriver('memory');
    });

    test('should initialize with all managers', () {
      expect(cacheManager, isNotNull);
      expect(cacheManager.driverNames, contains('memory'));
      expect(cacheManager.defaultDriverName, equals('memory'));
    });

    test('should store and retrieve values', () async {
      const key = 'test_key';
      const value = 'test_value';
      const ttl = Duration(minutes: 5);

      // Store value
      await cacheManager.put(key, value, ttl);

      // Retrieve value
      final retrieved = await cacheManager.get(key);

      expect(retrieved, equals(value));
    });

    test('should return null for non-existent keys', () async {
      final result = await cacheManager.get('non_existent_key');
      expect(result, isNull);
    });

    test('should check key existence', () async {
      const key = 'existing_key';
      const value = 'test_value';

      // Initially should not exist
      expect(await cacheManager.has(key), isFalse);

      // Store value
      await cacheManager.put(key, value, Duration(minutes: 5));

      // Now should exist
      expect(await cacheManager.has(key), isTrue);
    });

    test('should remove values', () async {
      const key = 'key_to_remove';
      const value = 'value_to_remove';

      // Store value
      await cacheManager.put(key, value, Duration(minutes: 5));
      expect(await cacheManager.has(key), isTrue);

      // Remove value
      await cacheManager.forget(key);
      expect(await cacheManager.has(key), isFalse);
    });

    test('should clear all values', () async {
      // Store multiple values
      await cacheManager.put('key1', 'value1', Duration(minutes: 5));
      await cacheManager.put('key2', 'value2', Duration(minutes: 5));

      expect(await cacheManager.has('key1'), isTrue);
      expect(await cacheManager.has('key2'), isTrue);

      // Clear all
      await cacheManager.clear();

      expect(await cacheManager.has('key1'), isFalse);
      expect(await cacheManager.has('key2'), isFalse);
    });

    test('should support remember pattern', () async {
      const key = 'remember_key';
      const expectedValue = 'computed_value';
      var callCount = 0;

      final result = await cacheManager.remember(
        key,
        Duration(minutes: 5),
        () async {
          callCount++;
          return expectedValue;
        },
      );

      expect(result, equals(expectedValue));
      expect(callCount, equals(1));

      // Second call should use cached value
      final cachedResult = await cacheManager.remember(
        key,
        Duration(minutes: 5),
        () async {
          callCount++;
          return 'should_not_be_called';
        },
      );

      expect(cachedResult, equals(expectedValue));
      expect(callCount, equals(1)); // Should not have increased
    });

    test('should support cache tagging', () async {
      const key1 = 'tagged_key1';
      const key2 = 'tagged_key2';
      const tag = 'test_tag';

      // Store tagged values
      await cacheManager.put(key1, 'value1', Duration(minutes: 5));
      await cacheManager.put(key2, 'value2', Duration(minutes: 5));
      await cacheManager.tag(key1, [tag]);
      await cacheManager.tag(key2, [tag]);

      // Both should exist
      expect(await cacheManager.has(key1), isTrue);
      expect(await cacheManager.has(key2), isTrue);

      // Forget by tag
      await cacheManager.forgetByTag(tag);

      // Both should be removed
      expect(await cacheManager.has(key1), isFalse);
      expect(await cacheManager.has(key2), isFalse);
    });

    test('should track statistics', () async {
      const key = 'stats_key';
      const value = 'stats_value';

      // Initially no stats
      expect(cacheManager.stats.hits, equals(0));
      expect(cacheManager.stats.misses, equals(0));

      // Get non-existent key (miss)
      await cacheManager.get(key);
      expect(cacheManager.stats.misses, equals(1));

      // Store value
      await cacheManager.put(key, value, Duration(minutes: 5));
      expect(cacheManager.stats.sets, equals(1));

      // Get existing key (hit)
      await cacheManager.get(key);
      expect(cacheManager.stats.hits, equals(1));

      // Check existence (hit)
      await cacheManager.has(key);
      expect(cacheManager.stats.hits, equals(2));
    });

    test('should validate inputs', () async {
      // Empty key should throw
      expect(
        () async => await cacheManager.put('', 'value', Duration(minutes: 5)),
        throwsA(isA<Exception>()),
      );

      // Negative TTL should throw
      expect(
        () async => await cacheManager.put('key', 'value', Duration(minutes: -1)),
        throwsA(isA<Exception>()),
      );
    });

    test('should support multiple drivers', () {
      // Register another driver
      cacheManager.registerDriver('memory2', MemoryCacheDriver());

      expect(cacheManager.driverNames, containsAll(['memory', 'memory2']));
      expect(cacheManager.defaultDriverName, equals('memory'));

      // Switch default driver
      cacheManager.setDefaultDriver('memory2');
      expect(cacheManager.defaultDriverName, equals('memory2'));
    });
  });
}
import 'package:khadem/src/support/cache_drivers/memory_cache_driver.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryCacheDriver', () {
    late MemoryCacheDriver driver;

    setUp(() {
      driver = MemoryCacheDriver();
    });

    test('should store and retrieve value', () async {
      await driver.put('key', 'value', const Duration(minutes: 5));

      final result = await driver.get('key');
      expect(result, equals('value'));
    });

    test('should return null for non-existent key', () async {
      final result = await driver.get('nonexistent');
      expect(result, isNull);
    });

    test('should check if key exists', () async {
      expect(await driver.has('nonexistent'), isFalse);

      await driver.put('key', 'value', const Duration(minutes: 5));
      expect(await driver.has('key'), isTrue);
    });

    test('should forget key', () async {
      await driver.put('key', 'value', const Duration(minutes: 5));
      expect(await driver.has('key'), isTrue);

      await driver.forget('key');
      expect(await driver.has('key'), isFalse);
    });

    test('should clear all keys', () async {
      await driver.put('key1', 'value1', const Duration(minutes: 5));
      await driver.put('key2', 'value2', const Duration(minutes: 5));

      expect(await driver.has('key1'), isTrue);
      expect(await driver.has('key2'), isTrue);

      await driver.clear();

      expect(await driver.has('key1'), isFalse);
      expect(await driver.has('key2'), isFalse);
    });

    test('should expire items after TTL', () async {
      await driver.put('key', 'value', const Duration(milliseconds: 100));

      // Should exist immediately
      expect(await driver.has('key'), isTrue);
      expect(await driver.get('key'), equals('value'));

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      // Should be expired
      expect(await driver.has('key'), isFalse);
      expect(await driver.get('key'), isNull);
    });

    test('should handle different data types', () async {
      await driver.put('string', 'hello', const Duration(minutes: 5));
      await driver.put('number', 42, const Duration(minutes: 5));
      await driver.put('boolean', true, const Duration(minutes: 5));
      await driver.put('list', [1, 2, 3], const Duration(minutes: 5));
      await driver.put('map', {'key': 'value'}, const Duration(minutes: 5));

      expect(await driver.get('string'), equals('hello'));
      expect(await driver.get('number'), equals(42));
      expect(await driver.get('boolean'), isTrue);
      expect(await driver.get('list'), equals([1, 2, 3]));
      expect(await driver.get('map'), equals({'key': 'value'}));
    });

    test('should handle overwriting values', () async {
      await driver.put('key', 'value1', const Duration(minutes: 5));
      expect(await driver.get('key'), equals('value1'));

      await driver.put('key', 'value2', const Duration(minutes: 5));
      expect(await driver.get('key'), equals('value2'));
    });
  });
}

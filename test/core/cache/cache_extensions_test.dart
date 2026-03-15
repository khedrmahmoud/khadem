import 'package:khadem/src/core/cache/cache_drivers/memory_cache_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Cache Extensions (MemoryDriver)', () {
    late MemoryCacheDriver driver;

    setUp(() {
      driver = MemoryCacheDriver();
    });

    test('add should store value only if key does not exist', () async {
      expect(
        await driver.add('key', 'value', const Duration(minutes: 1)),
        isTrue,
      );
      expect(await driver.get('key'), equals('value'));

      expect(
        await driver.add('key', 'new_value', const Duration(minutes: 1)),
        isFalse,
      );
      expect(await driver.get('key'), equals('value'));
    });

    test('many should retrieve multiple values', () async {
      await driver.put('key1', 'value1', const Duration(minutes: 1));
      await driver.put('key2', 'value2', const Duration(minutes: 1));

      final results = await driver.many(['key1', 'key2', 'key3']);
      expect(results, containsPair('key1', 'value1'));
      expect(results, containsPair('key2', 'value2'));
      expect(results, isNot(contains('key3')));
    });

    test('putMany should store multiple values', () async {
      await driver.putMany(
        {
          'key1': 'value1',
          'key2': 'value2',
        },
        const Duration(minutes: 1),
      );

      expect(await driver.get('key1'), equals('value1'));
      expect(await driver.get('key2'), equals('value2'));
    });

    test('increment should increase value', () async {
      await driver.put('counter', 10, const Duration(minutes: 1));
      expect(await driver.increment('counter'), equals(11));
      expect(await driver.increment('counter', 5), equals(16));
    });

    test('increment should start from 0 if key does not exist', () async {
      expect(await driver.increment('new_counter'), equals(1));
    });

    test('decrement should decrease value', () async {
      await driver.put('counter', 10, const Duration(minutes: 1));
      expect(await driver.decrement('counter'), equals(9));
      expect(await driver.decrement('counter', 5), equals(4));
    });

    test('pull should retrieve and delete value', () async {
      await driver.put('key', 'value', const Duration(minutes: 1));
      expect(await driver.pull('key'), equals('value'));
      expect(await driver.has('key'), isFalse);
    });
  });
}

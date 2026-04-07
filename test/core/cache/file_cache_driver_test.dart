import 'dart:io';

import 'package:khadem/src/core/cache/cache_drivers/file_cache_driver.dart';
import 'package:test/test.dart';

void main() {
  group('FileCacheDriver Security', () {
    late Directory tempDir;
    late FileCacheDriver driver;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('khadem_file_cache_');
      driver = FileCacheDriver(cacheDir: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('stores keys with traversal-like characters safely', () async {
      const key = '../etc/passwd\\..\\secret:file';
      await driver.put(key, 'value', const Duration(minutes: 1));

      final value = await driver.get(key);
      expect(value, equals('value'));

      final entities = await tempDir.list().toList();
      expect(
        entities.whereType<File>().any((f) => f.path.contains('..')),
        isFalse,
      );
    });

    test('rejects extremely long keys', () async {
      final longKey = 'k' * 3000;

      await expectLater(
        driver.put(longKey, 'value', const Duration(minutes: 1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('clear removes cache entries and keeps directory healthy', () async {
      await driver.put('alpha', '1', const Duration(minutes: 1));
      await driver.put('beta', '2', const Duration(minutes: 1));

      await driver.clear();

      expect(await driver.get('alpha'), isNull);
      expect(await driver.get('beta'), isNull);
      expect(await tempDir.exists(), isTrue);
    });

    test('clear throws when lock is active', () async {
      final lockFile = File('${tempDir.path}/.clear.lock');
      await lockFile.writeAsString('active', flush: true);

      await expectLater(driver.clear(), throwsA(isA<StateError>()));
    });

    test('clear recovers from stale lock file', () async {
      final lockFile = File('${tempDir.path}/.clear.lock');
      await lockFile.writeAsString('stale', flush: true);
      await lockFile.setLastModified(
        DateTime.now().subtract(const Duration(minutes: 2)),
      );

      await driver.clear();

      expect(await lockFile.exists(), isFalse);
    });
  });
}

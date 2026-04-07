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
  });
}

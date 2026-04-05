import 'dart:convert';
import 'dart:io';

import 'package:khadem/src/core/storage/local_disk.dart';
import 'package:test/test.dart';

void main() {
  group('LocalDisk', () {
    late LocalDisk disk;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('khadem_test_');
      disk = LocalDisk(basePath: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('putStream and getStream should write and read file', () async {
      const content = 'Hello Stream World';
      final stream = Stream.value(utf8.encode(content));

      await disk.putStream('stream.txt', stream);

      expect(await disk.exists('stream.txt'), isTrue);

      final readStream = disk.getStream('stream.txt');
      final readContent = await utf8.decodeStream(readStream);

      expect(readContent, equals(content));
    });

    test('makeDirectory should create directory', () async {
      await disk.makeDirectory('new_dir');

      final dir = Directory('${tempDir.path}/new_dir');
      expect(await dir.exists(), isTrue);
    });

    test('deleteDirectory should remove directory', () async {
      await disk.makeDirectory('del_dir');
      await disk.writeString('del_dir/file.txt', 'content');

      expect(await disk.exists('del_dir/file.txt'), isTrue);

      await disk.deleteDirectory('del_dir');

      final dir = Directory('${tempDir.path}/del_dir');
      expect(await dir.exists(), isFalse);
    });

    test('mimeType should return correct mime type', () async {
      expect(await disk.mimeType('image.jpg'), equals('image/jpeg'));
      expect(await disk.mimeType('doc.pdf'), equals('application/pdf'));
      expect(await disk.mimeType('data.json'), equals('application/json'));
      expect(await disk.mimeType('unknown.khedr_unknown_ext'), isNull);
    });

    test('temporaryUrl should return path', () async {
      await disk.writeString('file.txt', 'content');
      final url = await disk.temporaryUrl(
        'file.txt',
        DateTime.now().add(const Duration(hours: 1)),
      );
      // Since LocalDisk just returns the resolved path
      expect(url, contains('file.txt'));
    });

    test('should reject traversal paths', () async {
      await expectLater(
        disk.writeString('../outside.txt', 'blocked'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should reject absolute paths', () async {
      final absolute = File('${tempDir.path}/absolute.txt').absolute.path;

      await expectLater(
        disk.writeString(absolute, 'blocked'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

import 'dart:io';

import '../bus/command.dart';

class CacheClearCommand extends KhademCommand {
  CacheClearCommand({required super.logger});

  @override
  String get name => 'cache:clear';

  @override
  String get description => 'Clear application cache directories.';

  @override
  Future<void> handle(List<String> args) async {
    final candidates = <String>[
      'storage/cache',
      'storage/app/cache',
      'storage/framework/cache',
    ];

    final existing = <Directory>[];
    for (final candidate in candidates) {
      final dir = Directory(candidate);
      if (await dir.exists()) {
        existing.add(dir);
      }
    }

    if (existing.isEmpty) {
      logger.warning('No cache directories found to clear.');
      logger.info('Checked: ${candidates.join(', ')}');
      exitCode = 0;
      return;
    }

    try {
      for (final dir in existing) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
        logger.info('✅ Cleared ${dir.path}');
      }
      exitCode = 0;
    } catch (e) {
      logger.error('❌ Failed to clear cache: $e');
      exitCode = 1;
    }
  }
}

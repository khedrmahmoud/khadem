import 'dart:io';

import 'package:path/path.dart' as path;

import '../bus/command.dart';

class RoutesListCommand extends KhademCommand {
  RoutesListCommand({required super.logger});

  @override
  String get name => 'routes:list';

  @override
  String get description => 'List available route definition files.';

  @override
  Future<void> handle(List<String> args) async {
    final candidates = <String>[
      'routes',
      'lib/routes',
      'app/routes',
      // This repo ships routes under example/
      'example/lib/routes',
    ];

    final foundDirs = <Directory>[];
    for (final candidate in candidates) {
      final dir = Directory(candidate);
      if (await dir.exists()) {
        foundDirs.add(dir);
      }
    }

    if (foundDirs.isEmpty) {
      logger.error('❌ No routes directory found.');
      logger.info('Checked: ${candidates.join(', ')}');
      exitCode = 1;
      return;
    }

    final files = <String>[];
    for (final dir in foundDirs) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.dart')) {
          files.add(path.normalize(entity.path));
        }
      }
    }

    files.sort();

    logger.info('Route files:');
    for (final file in files) {
      logger.info('  - ${path.relative(file)}');
    }

    exitCode = 0;
  }
}

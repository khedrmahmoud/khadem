import 'dart:io';

import '../bus/command.dart';

class DeployCommand extends KhademCommand {
  DeployCommand({required super.logger}) {
    argParser.addOption('output',
        abbr: 'o', defaultsTo: 'build/deploy', help: 'Output directory');
  }

  @override
  String get name => 'deploy';
  @override
  String get description =>
      'Prepare the project for deployment with optimized structure';

  @override
  Future<void> handle(List<String> args) async {
    final output = argResults?['output'] as String;
    logger.info('🚀 Preparing deployment package...');

    final outputDir = Directory(output);
    await outputDir.create(recursive: true);

    final result = await Process.run(
        'dart', ['compile', 'exe', 'bin/server.dart', '-o', '$output/server']);
    if (result.exitCode != 0) {
      logger.error('❌ Deployment build failed: ${result.stderr}');
      exit(1);
    }

    await File('.env').copy('$output/.env');
    await _copyDirectory(Directory('public'), Directory('$output/public'));
    await _copyDirectory(Directory('storage'), Directory('$output/storage'));

    logger.info('✅ Deployment folder ready at: $output');
    exit(0);
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await source.exists()) return;
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final newPath = '${destination.path}/${entity.uri.pathSegments.last}';
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }
}

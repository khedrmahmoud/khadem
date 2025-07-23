import 'dart:async';
import 'dart:io';

import '../bus/command.dart';

class BuildCommand extends KhademCommand {
  BuildCommand({required super.logger}) {
    argParser.addOption('output',
        abbr: 'o', defaultsTo: 'bin/server.jit', help: 'Output path');
    argParser.addFlag('archive',
        abbr: 'a', defaultsTo: false, help: 'Create a tar.gz archive');
    //delete temp directory
    argParser.addFlag('delete-temp',
        abbr: 'd', defaultsTo: true, help: 'Delete temp directory');
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (var entity in source.list(recursive: true)) {
      final relativePath = entity.path.substring(source.path.length + 1);
      final newPath = '${destination.path}/$relativePath';

      if (entity is File) {
        final newFile = File(newPath);
        await newFile.parent.create(recursive: true);
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
      }
    }
  }

  Future<void> _copyFileIfExists(String sourcePath, String destPath) async {
    final file = File(sourcePath);
    if (await file.exists()) {
      await File(sourcePath).copy(destPath);
      logger.info('📄 Included: $sourcePath');
    }
  }

  Future<void> _copyJsonFilesRecursively(Directory from, Directory to) async {
    await for (var entity in from.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        final relative = entity.path.replaceFirst(from.path, '');
        final dest = File('${to.path}/$relative');
        await dest.parent.create(recursive: true);
        await entity.copy(dest.path);
        logger.info('📄 Included: ${entity.path}');
      }
    }
  }

  @override
  Future<void> handle(List<String> args) async {
    final output = argResults?['output'] ?? 'bin/server.jit';
    final createArchive = (argResults?['archive'] ?? false) as bool;
    final deleteTemp = (argResults?['delete-temp'] ?? true) as bool;
    final outputDir = Directory(output).parent;

    await outputDir.create(recursive: true);

    // Progress spinner simulation
    var seconds = 0;
    stdout.write('🛠️ Compiling project to snapshot');
    final timer = Timer.periodic(Duration(seconds: 1), (_) {
      seconds++;
      stdout.write('.');
    });

    final compile = await Process.run(
      'dart',
      [
        'compile',
        'jit-snapshot',
        'bin/server.dart',
        '-o',
        output,
        '--obfuscate',
      ],
      environment: {
        'KHADIM_JIT_TRAINING': '1',
      },
    );

    timer.cancel();
    stdout.writeln(); // New line

    if (compile.exitCode != 0) {
      logger.error('❌ Build failed after ${seconds}s: ${compile.stderr}');
      exit(1);
    }

    logger.info('✅ Snapshot created in ${seconds}s: $output');

    if (createArchive) {
      final tempDir = Directory('build/output');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      // Copy bin/server.jit
      if (!await Directory('${tempDir.path}/bin').exists()) {
        await Directory('${tempDir.path}/bin').create(recursive: true);
      }
      await File(output).copy('${tempDir.path}/bin/server.jit');

      // Copy .env
      await _copyFileIfExists('.env', '${tempDir.path}/.env');

      // Copy config/**/*.json
      final configDir = Directory('config');
      if (await configDir.exists()) {
        await _copyJsonFilesRecursively(
            configDir, Directory('${tempDir.path}/config'));
      }

      // Copy public/
      final publicDir = Directory('public');
      if (await publicDir.exists()) {
        await _copyDirectory(publicDir, Directory('${tempDir.path}/public'));
      }

      // Copy storage/
      final storageDir = Directory('storage');
      if (await storageDir.exists()) {
        await _copyDirectory(storageDir, Directory('${tempDir.path}/storage'));
      }

      final archivePath =
          'build/${output.split('/').last.replaceAll('.jit', '')}.tar.gz';
      logger.info('📦 Creating archive: $archivePath');

      final result = await Process.run(
        'tar',
        ['-czf', archivePath, '-C', tempDir.path, '.'],
      );

      if (result.exitCode != 0) {
        logger.error('❌ Archive failed: ${result.stderr}');
        exit(1);
      }

      logger.info('✅ Archive created: $archivePath');
      if (deleteTemp) {
        await tempDir.delete(recursive: true);
      }
    }

    logger.info('🎯 Build process finished successfully');
  }

  @override
  String get description =>
      'Build the project as a JIT snapshot executable for production';

  @override
  String get name => 'build';
}

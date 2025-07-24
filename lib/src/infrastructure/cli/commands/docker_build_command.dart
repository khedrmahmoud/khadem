import 'dart:io';
import '../bus/command.dart';

class DockerBuildCommand extends KhademCommand {
  DockerBuildCommand({required super.logger}) {
    argParser.addOption('tag',
        abbr: 't', defaultsTo: 'khadem:latest', help: 'Docker image tag');
  }

  @override
  String get name => 'docker:build';

  @override
  String get description =>
      'Prepare build/output and build Docker image without compiling snapshot';

  @override
  Future<void> handle(List<String> args) async {
    final tag = argResults?['tag'] as String;
    final outputDir = Directory('build/output');
    // ✅ Check if Docker is installed
    await Process.run('docker', ['--version'])
        .then((value) => value.exitCode)
        .catchError((e) {
      logger.error(
          '❌ Docker is not installed or not found in PATH.\nPlease install Docker and make sure the "docker" command is available.');
      exit(1);
    });

    // Clean existing output
    if (await outputDir.exists()) {
      await outputDir.delete(recursive: true);
    }
    await outputDir.create(recursive: true);

    // Check server.jit exists
    final snapshot = File('bin/server.jit');
    if (!await snapshot.exists()) {
      logger.error(
          '❌ bin/server.jit not found. Please compile it first manually.');
      exit(1);
    }

    // Copy snapshot
    final binDir = Directory('${outputDir.path}/bin');
    await binDir.create(recursive: true);
    await snapshot.copy('${binDir.path}/server.jit');

    // Copy .env
    await _copyFileIfExists('.env', '${outputDir.path}/.env');

    // Copy config/**/*.json
    final configDir = Directory('config');
    if (await configDir.exists()) {
      await _copyJsonFilesRecursively(
          configDir, Directory('${outputDir.path}/config'));
    }

    // Copy public/
    final publicDir = Directory('public');
    if (await publicDir.exists()) {
      await _copyDirectory(publicDir, Directory('${outputDir.path}/public'));
    }

    // Copy storage/
    final storageDir = Directory('storage');
    if (await storageDir.exists()) {
      await _copyDirectory(storageDir, Directory('${outputDir.path}/storage'));
    }

    // Create Dockerfile if not exists
    final dockerfilePath = File('${outputDir.path}/Dockerfile');
    if (!await dockerfilePath.exists()) {
      logger.info('📝 Generating default Dockerfile...');
      await dockerfilePath.writeAsString(_defaultDockerfile());
    }

    // Docker build
    logger.info('🐳 Building Docker image: $tag...');
    final result =
        await Process.run('docker', ['build', '-t', tag, outputDir.path]);

    if (result.exitCode == 0) {
      logger.info('✅ Docker image built successfully: $tag');
    } else {
      logger.error('❌ Docker build failed:\n${result.stderr}');
      exit(1);
    }

    exit(0);
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

  String _defaultDockerfile() => '''
FROM dart:stable

WORKDIR /app

COPY . .

CMD ["dart", "bin/server.jit"]
''';
}

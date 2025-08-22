import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import '../bus/command.dart';

class DockerBuildCommand extends KhademCommand {
  DockerBuildCommand({required super.logger}) {
    argParser.addOption(
      'tag',
      abbr: 't',
      defaultsTo: 'khadem:latest',
      help: 'Docker image tag',
    );
  }

  @override
  String get name => 'docker:build';

  @override
  String get description =>
      'Prepare build/output and build Docker image with local khadem framework.';

  @override
  Future<void> handle(List<String> args) async {
    final tag = argResults?['tag'] as String;
    final outputDir = Directory('build/output');

    // ✅ Check if Docker is installed
    final check = await Process.run('docker', ['--version']);
    if (check.exitCode != 0) {
      logger.error('❌ Docker not found in PATH. Please install Docker first.');
      exit(1);
    }

    // Clean & recreate output dir
    if (await outputDir.exists()) {
      await outputDir.delete(recursive: true);
    }
    await outputDir.create(recursive: true);

    // --- 1️⃣ Read pubspec.yaml and find khadem path ---
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      logger.error('❌ pubspec.yaml not found.');
      exit(1);
    }
    final pubspecContent = await pubspecFile.readAsString();
    final pubspecMap = loadYaml(pubspecContent) as Map;
    String? khademPath = pubspecMap['dependencies']?['khadem']?['path'];

    if (khademPath == null || !Directory(khademPath).existsSync()) {
      logger.error('❌ Could not find local khadem path in pubspec.yaml.');
      exit(1);
    }

    logger.info('📦 Found local khadem at: $khademPath');

    // --- 2️⃣ Copy khadem framework into outputDir ---
    await _copyDirectory(
        Directory(khademPath), Directory('${outputDir.path}/khadem'));

    // --- 3️⃣ Copy all project files ---
    await _copyDirectory(Directory('.'), outputDir);

    // --- 4️⃣ Update pubspec.yaml to use relative path ---
    final newPubspecPath = '${outputDir.path}/pubspec.yaml';
    final yamlEditor = YamlEditor(await File(newPubspecPath).readAsString());
    yamlEditor.update(['dependencies', 'khadem', 'path'], './khadem');
    await File(newPubspecPath).writeAsString(yamlEditor.toString());
    logger.info('✏️ Updated pubspec.yaml to use ./khadem');

    // --- 5️⃣ Create Dockerfile ---
    final dockerfilePath = File('${outputDir.path}/Dockerfile');
    await dockerfilePath.writeAsString(_defaultDockerfile());

    // --- 6️⃣ Build Docker image ---
    logger.info('🐳 Building Docker image: $tag...');
    final result =
        await Process.run('docker', ['build', '-t', tag, outputDir.path]);

    if (result.exitCode == 0) {
      logger.info('✅ Docker image built successfully: $tag');
    } else {
      logger.error('❌ Docker build failed:\n${result.stderr}');
      exit(1);
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (var entity in source.list(recursive: true)) {
      final relativePath = entity.path.substring(source.path.length + 1);
      final newPath = '${destination.path}/$relativePath';
      if (entity is File) {
        await File(newPath).parent.create(recursive: true);
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
      }
    }
  }

  String _defaultDockerfile() => '''
FROM dart:stable
WORKDIR /app
COPY . .
RUN dart pub get
CMD ["dart", "run", "bin/server.dart"]
''';
}

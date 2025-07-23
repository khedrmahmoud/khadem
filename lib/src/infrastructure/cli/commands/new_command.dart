import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

import '../bus/command.dart';

class NewCommand extends KhademCommand {
  @override
  String get name => 'new';

  @override
  String get description => 'Create a new Khadem Dart project';

  NewCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Project name');
  }

  @override
  Future<void> run() async {
    try {
      await handle(argResults!.arguments);
    } catch (e, stack) {
      logger.error('❌ Command failed: $e');
      logger.debug(stack.toString());
    }
    exit(exitCode);
  }

  @override
  Future<void> handle(List<String> args) async {
    final projectName = argResults?['name'] as String?;
    if (projectName == null) {
      logger.error('Usage: khadem new --name=<project_name>');
      exit(1);
    }
    final scriptUri = Platform.script;
    final templateDir = _getKhademTemplateRootDirectory(scriptUri);

    final targetPath =
        Directory.current.path + Platform.pathSeparator + projectName;

    if (!templateDir.existsSync()) {
      logger.error('❌ Template directory not found at $templateDir');
      exit(1);
    }

    logger.info('📁 Creating new project: $projectName');
    await _copyAndReplace(templateDir, Directory(targetPath), projectName);
    await _updateEnvFile(targetPath, projectName);

    logger.info('✅ Project "$projectName" created successfully!');
    logger.info('👉 Next: cd $projectName && dart pub get');
    exit(0);
  }

  Directory _getKhademTemplateRootDirectory(Uri scriptUri) {
    final fullPath = Directory.fromUri(scriptUri).path.replaceAll('\\', '/');
    final khademIndex = fullPath.indexOf('/khadem/');

    if (khademIndex == -1) {
      throw Exception(
          '❌ Unable to locate "khadem" directory in the script path.');
    }

    final khademPath =
        '${fullPath.substring(0, khademIndex + '/khadem'.length)}/khadem_template';
    return Directory(khademPath);
  }

  Future<void> _copyAndReplace(
      Directory source, Directory target, String projectName) async {
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      final newPath = p.join(target.path, name);

      if (entity is File) {
        String content = await entity.readAsString();

        // 🔁 Replace placeholders
        content = content.replaceAll('{{app_name}}', projectName);
        content = content.replaceAll('khadem_template', projectName);

        await File(newPath).writeAsString(content);
      } else if (entity is Directory) {
        await _copyAndReplace(entity, Directory(newPath), projectName);
      }
    }
  }

  Future<void> _updateEnvFile(String projectPath, String projectName) async {
    final envPath = p.join(projectPath, '.env');
    final envFile = File(envPath);

    if (!envFile.existsSync()) {
      logger.warning('⚠️ No .env file found to configure.');
      return;
    }

    String content = await envFile.readAsString();

    final jwtSecret = _generateJwtSecret();

    content = content.replaceAll(RegExp(r'(?<=APP_NAME=).*'), projectName);
    content = content.replaceAll(
      RegExp(r'(?<=JWT_SECRET=).*'),
      '"$jwtSecret"',
    );

    await envFile.writeAsString(content);
    logger.info('🔐 .env file configured with app name and new JWT secret');
  }

  String _generateJwtSecret({int length = 64}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}

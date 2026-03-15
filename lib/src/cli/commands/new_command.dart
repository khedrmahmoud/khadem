import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

import '../../contracts/cli/command.dart';
import '../../support/utils/package_metadata.dart';

class NewCommand extends KhademCommand {
  @override
  String get name => 'new';

  @override
  String get description => 'Create a new Khadem Dart project';

  NewCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Project name');
  }

  @override
  Future<void> handle(List<String> args) async {
    final projectName = argResults?['name'] as String?;
    if (projectName == null) {
      logger.error('Usage: khadem new --name=<project_name>');
      exitCode = 1;
      return;
    }

    final targetPath =
        Directory.current.path + Platform.pathSeparator + projectName;

    // Check if target directory already exists
    if (Directory(targetPath).existsSync()) {
      logger.error('❌ Directory "$projectName" already exists');
      exitCode = 1;
      return;
    }

    logger.info('📁 Creating new project: $projectName');
    logger.info('📥 Cloning template from GitHub...');

    try {
      // Clone the template repository
      await _cloneTemplate(targetPath);

      // Clean up git directory
      await _cleanupGitDirectory(targetPath);

      // Remove template license file (projects should provide their own)
      await _cleanupLicenseFiles(targetPath);

      // Replace placeholders in files
      await _replaceProjectPlaceholders(Directory(targetPath), projectName);

      // Update .env file
      await _updateEnvFile(targetPath, projectName);

      logger.info('✅ Project "$projectName" created successfully!');
      logger.info('👉 Next: cd $projectName && dart pub get');
      exitCode = 0;
      return;
    } catch (e) {
      logger.error('❌ Failed to create project: $e');
      // Clean up partial directory if it exists
      if (Directory(targetPath).existsSync()) {
        await Directory(targetPath).delete(recursive: true);
      }
      exitCode = 1;
      return;
    }
  }

  Future<void> _cloneTemplate(String targetPath) async {
    final frameworkVersion = KhademPackageMetadataLoader.loadSync().version;
    // We target a branch or tag that matches the framework version, or fallback if unknown.
    // E.g., if version is 2.0.0, we try to clone branch/tag 'v2.0.0'.
    final branchName =
        frameworkVersion != 'unknown' ? 'v$frameworkVersion' : 'main';

    logger.debug('Cloning template version: $branchName');

    // Clone the template repository
    final result = await Process.run(
      'git',
      [
        'clone',
        '-b',
        branchName,
        '--depth',
        '1',
        'https://github.com/khadem-framework/khadem-template.git',
        targetPath,
      ],
    );

    if (result.exitCode != 0) {
      throw Exception(
          'Failed to clone template (branch: $branchName): ${result.stderr}');
    }
  }

  Future<void> _cleanupGitDirectory(String projectPath) async {
    final gitDir = Directory(p.join(projectPath, '.git'));
    if (gitDir.existsSync()) {
      await gitDir.delete(recursive: true);
      logger.info('🧹 Cleaned up git directory');
    }
  }

  Future<void> _cleanupLicenseFiles(String projectPath) async {
    final candidates = <String>[
      'LICENSE',
      'LICENSE.md',
      'LICENCE',
      'LICENCE.md',
    ];

    var deleted = 0;
    for (final name in candidates) {
      final file = File(p.join(projectPath, name));
      if (file.existsSync()) {
        await file.delete();
        deleted++;
      }
    }

    if (deleted > 0) {
      logger.info('🧹 Removed template license file(s)');
    }
  }

  Future<void> _replaceProjectPlaceholders(
    Directory projectDir,
    String projectName,
  ) async {
    await for (final entity in projectDir.list(recursive: true)) {
      if (entity is File) {
        // Check if file is binary (don't try to read as text)
        final isBinary = await _isBinaryFile(entity);

        if (!isBinary) {
          try {
            // Handle text files with placeholder replacement
            String content = await entity.readAsString();

            // 🔁 Replace placeholders
            content = content.replaceAll('khadem_app', projectName);
            content = content.replaceAll('khadem_template', projectName);

            await entity.writeAsString(content);
          } catch (e) {
            // Skip files that can't be read as text
            logger.debug('Skipping file: ${entity.path} - $e');
          }
        }
      }
    }
    logger.info('🔄 Updated project placeholders');
  }

  Future<void> _updateEnvFile(String projectPath, String projectName) async {
    final envPath = p.join(projectPath, '.env');
    final examplePath = p.join(projectPath, '.env.example');
    final envFile = File(envPath);

    final jwtSecret = _generateJwtSecret();

    // Use the template's env file when available; otherwise create one.
    if (!envFile.existsSync() && File(examplePath).existsSync()) {
      await File(examplePath).copy(envPath);
      logger.info('✅ Copied .env.example to .env');
    }

    if (envFile.existsSync()) {
      // Keep the template's .env structure intact and only update specific values.
      var content = await envFile.readAsString();
      content = _replaceEnvValue(content, 'APP_NAME', projectName);
      content = _replaceEnvValue(content, 'JWT_SECRET', '"$jwtSecret"');

      await envFile.writeAsString(content);
      logger.info('✅ Updated .env with project name and generated JWT secret');
      return;
    }

    // Fallback: create a simple default .env file if the template didn't provide one.
    await envFile.writeAsString(_getDefaultEnvContent(projectName, jwtSecret));
    logger.info('✅ Created .env file with default configuration');
  }

  String _replaceEnvValue(String content, String key, String value) {
    final regex = RegExp(r'^(\s*${RegExp.escape(key)}\s*=).*', multiLine: true);
    if (regex.hasMatch(content)) {
      return content.replaceAllMapped(
          regex, (match) => '${match.group(1)}$value');
    }

    // If the key does not exist, append it.
    return '$content\n$key=$value\n';
  }

  String _getDefaultEnvContent(String projectName, String jwtSecret) {
    return '''# Application Configuration
APP_NAME=$projectName
APP_ENV=development
APP_LOCALE=en
APP_PORT=9000
SOCKET_PORT=8080
APP_URL=http://localhost:9000

# Database Configuration (configure based on your database choice)
# For MySQL
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_NAME=${projectName.toLowerCase()}_db
DB_USER=${projectName.toLowerCase()}_user
DB_PASSWORD=your_password

# For JWT Authentication
JWT_SECRET="$jwtSecret"
JWT_ACCESS_EXPIRY_MINUTES=60
JWT_REFRESH_EXPIRY_DAYS=30

# For MongoDB (uncomment and comment others above)
# MONGO_CONNECTION=mongodb://localhost:27017/${projectName.toLowerCase()}_db

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Session Configuration
SESSION_DRIVER=file
SESSION_LIFETIME=7200

# Cache Configuration
CACHE_DRIVER=file
CACHE_PREFIX=${projectName.toLowerCase()}

# Logging
LOG_CHANNEL=stack
LOG_LEVEL=debug

# File Storage
FILESYSTEM_DISK=local

# Production Docker overrides (these will be overridden in docker-compose.yml)
# APP_ENV will be set to 'production' in Docker
# DB_HOST will be set to 'database' for Docker services
# REDIS_HOST will be set to 'redis' for Docker services
''';
  }

  String _generateJwtSecret({int length = 64}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<bool> _isBinaryFile(File file) async {
    // Check file extension for known binary files
    final extension = p.extension(file.path).toLowerCase();
    final binaryExtensions = [
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.ico',
      '.svg',
      '.woff',
      '.woff2',
      '.ttf',
      '.eot',
    ];

    if (binaryExtensions.contains(extension)) {
      return true;
    }

    // For other files, check for null bytes in the first 512 bytes
    try {
      final bytes = await file.openRead(0, 512).first;
      return bytes.contains(0);
    } catch (e) {
      // If we can't read the file, assume it's binary to be safe
      return true;
    }
  }
}

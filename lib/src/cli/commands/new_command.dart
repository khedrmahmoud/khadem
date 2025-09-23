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

    final targetPath =
        Directory.current.path + Platform.pathSeparator + projectName;

    // Check if target directory already exists
    if (Directory(targetPath).existsSync()) {
      logger.error('❌ Directory "$projectName" already exists');
      exit(1);
    }

    logger.info('📁 Creating new project: $projectName');
    logger.info('📥 Cloning template from GitHub...');

    try {
      // Clone the template repository
      await _cloneTemplate(targetPath);

      // Clean up git directory
      await _cleanupGitDirectory(targetPath);

      // Replace placeholders in files
      await _replaceProjectPlaceholders(Directory(targetPath), projectName);

      // Update .env file
      await _updateEnvFile(targetPath, projectName);

      logger.info('✅ Project "$projectName" created successfully!');
      logger.info('👉 Next: cd $projectName && dart pub get');
      exit(0);
    } catch (e) {
      logger.error('❌ Failed to create project: $e');
      // Clean up partial directory if it exists
      if (Directory(targetPath).existsSync()) {
        await Directory(targetPath).delete(recursive: true);
      }
      exit(1);
    }
  }

  Future<void> _cloneTemplate(String targetPath) async {
    // Clone the template repository
    final result = await Process.run(
      'git',
      [
        'clone',
        'https://github.com/khadem-framework/khadem-template.git',
        targetPath,
      ],
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to clone template: ${result.stderr}');
    }
  }

  Future<void> _cleanupGitDirectory(String projectPath) async {
    final gitDir = Directory(p.join(projectPath, '.git'));
    if (gitDir.existsSync()) {
      await gitDir.delete(recursive: true);
      logger.info('🧹 Cleaned up git directory');
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
    final envFile = File(envPath);

    String content;
    if (envFile.existsSync()) {
      // If .env exists, read and update it
      content = await envFile.readAsString();

      final jwtSecret = _generateJwtSecret();
      content = content.replaceAll(RegExp(r'(?<=APP_NAME=).*'), projectName);
      content = content.replaceAll(
        RegExp(r'(?<=JWT_SECRET=).*'),
        '"$jwtSecret"',
      );
    } else {
      // Create a new .env file with default content
      final jwtSecret = _generateJwtSecret();
      content = _getDefaultEnvContent(projectName, jwtSecret);
    }

    await envFile.writeAsString(content);
    logger.info('🔐 .env file configured with app name and new JWT secret');
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

import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../bus/command.dart';

class BuildCommand extends KhademCommand {
  BuildCommand({required super.logger}) {
    argParser.addOption('output',
        abbr: 'o',
        defaultsTo: 'bin/server.exe',
        help: 'Output path for the executable',
    );
    argParser.addFlag('aot',
        abbr: 'a',
        help: 'Use AOT compilation for better production performance',
    );
    argParser.addFlag('archive',
        abbr: 'r',
        help: 'Create a tar.gz archive with all necessary files',
    );
    argParser.addFlag('docker',
        abbr: 'c',
        help: 'Generate Dockerfile for cross-platform deployment',
    );
    argParser.addOption('services',
        abbr: 'e',
        help: 'Specify external services to include (mysql,redis,nginx,postgres,mongo,none)',
        defaultsTo: 'none',
    );
    argParser.addFlag('source-deploy',
        abbr: 's',
        help: 'Prepare source-only deployment (compile on target)',
    );
    argParser.addFlag('delete-temp',
        abbr: 'd',
        defaultsTo: true,
        help: 'Delete temporary files after build',
    );
    argParser.addFlag('verbose',
        abbr: 'v',
        help: 'Enable verbose logging',
    );
  }

  Future<void> _addDirectoryToArchive(Archive archive, Directory dir, String basePath) async {
    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: dir.path);
        final archivePath = path.join(basePath, relativePath).replaceAll('\\', '/');
        final bytes = await entity.readAsBytes();
        final archiveFile = ArchiveFile(archivePath, bytes.length, bytes);
        archive.addFile(archiveFile);
        if (argResults?['verbose'] == true) {
          logger.info(' Added to archive: ');
        }
      }
    }
  }

  Future<void> _addFileToArchiveIfExists(Archive archive, String filePath, String archivePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final archiveFile = ArchiveFile(archivePath.replaceAll('\\', '/'), bytes.length, bytes);
      archive.addFile(archiveFile);
      if (argResults?['verbose'] == true) {
        logger.info(' Added to archive: ');
      }
    }
  }

  Future<void> _generateDockerfile() async {
    const dockerfileContent = '''
# Multi-stage Docker build for Khadem Dart application
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline

# Build AOT executable for production
RUN dart compile exe bin/server.dart -o bin/server --obfuscate

# Production stage
FROM debian:bookworm-slim

# Install ca-certificates for HTTPS connections
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash app
USER app

WORKDIR /app

# Copy runtime and application
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Copy application files
COPY --from=build /app/.env* /app/
COPY --from=build /app/config/ /app/config/
COPY --from=build /app/public/ /app/public/
COPY --from=build /app/storage/ /app/storage/

EXPOSE 9000
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\
  CMD curl -f http://localhost:9000/health || exit 1

CMD ["/app/bin/server"]
''';

    const dockerfilePath = 'Dockerfile';
    await File(dockerfilePath).writeAsString(dockerfileContent);
    logger.info('🐳 Generated production-ready Dockerfile');

    // Generate docker-compose.yml based on selected services
    final services = argResults?['services'] as String? ?? 'none';
    final dockerCompose = await _generateDockerCompose(services);

    await File('docker-compose.yml').writeAsString(dockerCompose);
    logger.info('📝 Generated docker-compose.yml for external services');

    // Also generate .dockerignore
    const dockerignore = '''
.git
.github
.vscode
.idea
build/
.dart_tool/
pubspec.lock
*.log
*.md
docs/
test/
coverage/
*.tar.gz
Dockerfile*
docker-compose*
''';

    await File('.dockerignore').writeAsString(dockerignore);
    logger.info('📝 Generated .dockerignore file');

    // Generate environment template
    const envTemplate = '''
# Application Configuration
APP_ENV=development
APP_PORT=9000
SOCKET_PORT=8080
APP_URL=http://localhost:9000

# Database Configuration (configure based on your database choice)
# For MySQL
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_NAME=khadem_db
DB_USER=khadem_user
DB_PASSWORD=your_password

# For PostgreSQL (uncomment and comment MySQL above)
# DB_CONNECTION=postgresql
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=khadem_db
# DB_USER=khadem_user
# DB_PASSWORD=your_password

# For MongoDB (uncomment and comment others above)
# MONGO_CONNECTION=mongodb://localhost:27017/khadem_db

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Session Configuration
SESSION_DRIVER=file
SESSION_LIFETIME=7200

# Cache Configuration
CACHE_DRIVER=file
CACHE_PREFIX=khadem

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

    await File('.env.example').writeAsString(envTemplate);
    logger.info('📝 Generated .env.example template');
  }

  Future<String> _generateDockerCompose(String services) async {
    final serviceList = services.split(',').map((s) => s.trim().toLowerCase()).toList();
    final buffer = StringBuffer();
    buffer.writeln('services:');

    // Always include the app service
    buffer.writeln('  khadem-app:');
    buffer.writeln('    build: .');
    buffer.writeln('    ports:');
    buffer.writeln('      - "9000:9000"');
    buffer.writeln('      - "8080:8080"');
    buffer.writeln('    env_file:');
    buffer.writeln('      - .env');
    buffer.writeln('    environment:');
    buffer.writeln('      # Production overrides');
    buffer.writeln('      - APP_ENV=production');

    final dependsOn = <String>[];

    // Check for dependencies
    if (serviceList.contains('mysql') || serviceList.contains('postgres') || serviceList.contains('mongo')) {
      dependsOn.add('database');
    }
    if (serviceList.contains('redis')) {
      dependsOn.add('redis');
    }

    // Add depends_on if there are dependencies
    if (dependsOn.isNotEmpty) {
      buffer.writeln('    depends_on:');
      for (final dep in dependsOn) {
        buffer.writeln('      - $dep');
      }
    }

    buffer.writeln('    networks:');
    buffer.writeln('      - khadem-network');
    buffer.writeln('    restart: unless-stopped');

    // Add database services after the app service
    if (serviceList.contains('mysql')) {
      buffer.writeln();
      buffer.writeln('  database:');
      buffer.writeln('    image: mysql:8.0');
      buffer.writeln('    env_file:');
      buffer.writeln('      - .env');
      buffer.writeln('    environment:');
      buffer.writeln('      # Database service configuration');
      buffer.writeln('      - MYSQL_ROOT_PASSWORD=${r'$'}{DB_PASSWORD:-root_password}');
      buffer.writeln('      - MYSQL_DATABASE=${r'$'}{DB_NAME:-khadem_db}');
      buffer.writeln('      - MYSQL_USER=${r'$'}{DB_USER:-khadem_user}');
      buffer.writeln('      - MYSQL_PASSWORD=${r'$'}{DB_PASSWORD:-your_password}');
      buffer.writeln('    ports:');
      buffer.writeln('      - "${r'$'}{DB_PORT:-3306}:3306"');
      buffer.writeln('    volumes:');
      buffer.writeln('      - mysql_data:/var/lib/mysql');
      buffer.writeln('    command: --default-authentication-plugin=mysql_native_password');
      buffer.writeln('    networks:');
      buffer.writeln('      - khadem-network');
      buffer.writeln('    restart: unless-stopped');
    }

    if (serviceList.contains('postgres')) {
      buffer.writeln();
      buffer.writeln('  database:');
      buffer.writeln('    image: postgres:15-alpine');
      buffer.writeln('    env_file:');
      buffer.writeln('      - .env');
      buffer.writeln('    environment:');
      buffer.writeln('      # Database service configuration');
      buffer.writeln('      - POSTGRES_DB=${r'$'}{DB_NAME:-khadem_db}');
      buffer.writeln('      - POSTGRES_USER=${r'$'}{DB_USER:-khadem_user}');
      buffer.writeln('      - POSTGRES_PASSWORD=${r'$'}{DB_PASSWORD:-your_password}');
      buffer.writeln('    ports:');
      buffer.writeln('      - "${r'$'}{DB_PORT:-5432}:5432"');
      buffer.writeln('    volumes:');
      buffer.writeln('      - postgres_data:/var/lib/postgresql/data');
      buffer.writeln('    networks:');
      buffer.writeln('      - khadem-network');
      buffer.writeln('    restart: unless-stopped');
    }

    if (serviceList.contains('mongo')) {
      buffer.writeln();
      buffer.writeln('  database:');
      buffer.writeln('    image: mongo:7-jammy');
      buffer.writeln('    env_file:');
      buffer.writeln('      - .env');
      buffer.writeln('    environment:');
      buffer.writeln('      # Database service configuration');
      buffer.writeln('      - MONGO_INITDB_DATABASE=${r'$'}{DB_NAME:-khadem_db}');
      buffer.writeln('    ports:');
      buffer.writeln('      - "${r'$'}{DB_PORT:-27017}:27017"');
      buffer.writeln('    volumes:');
      buffer.writeln('      - mongo_data:/data/db');
      buffer.writeln('    networks:');
      buffer.writeln('      - khadem-network');
      buffer.writeln('    restart: unless-stopped');
    }

    // Add Redis if requested
    if (serviceList.contains('redis')) {
      buffer.writeln();
      buffer.writeln('  redis:');
      buffer.writeln('    image: redis:7-alpine');
      buffer.writeln('    env_file:');
      buffer.writeln('      - .env');
      buffer.writeln('    ports:');
      buffer.writeln('      - "${r'$'}{REDIS_PORT:-6379}:6379"');
      buffer.writeln('    volumes:');
      buffer.writeln('      - redis_data:/data');
      buffer.writeln('    command: redis-server --requirepass ${r'$'}{REDIS_PASSWORD:-}');
      buffer.writeln('    networks:');
      buffer.writeln('      - khadem-network');
      buffer.writeln('    restart: unless-stopped');
    }

    // Add Nginx if requested
    if (serviceList.contains('nginx')) {
      buffer.writeln();
      buffer.writeln('  nginx:');
      buffer.writeln('    image: nginx:alpine');
      buffer.writeln('    ports:');
      buffer.writeln('      - "80:80"');
      buffer.writeln('      - "443:443"');
      buffer.writeln('    volumes:');
      buffer.writeln('      - ./nginx.conf:/etc/nginx/nginx.conf:ro');
      buffer.writeln('      - ./ssl:/etc/nginx/ssl:ro');
      buffer.writeln('    depends_on:');
      buffer.writeln('      - khadem-app');
      buffer.writeln('    networks:');
      buffer.writeln('      - khadem-network');
      buffer.writeln('    restart: unless-stopped');
    }

    // Add volumes section
    buffer.writeln();
    buffer.writeln('volumes:');
    if (serviceList.contains('mysql')) {
      buffer.writeln('  mysql_data:');
    }
    if (serviceList.contains('postgres')) {
      buffer.writeln('  postgres_data:');
    }
    if (serviceList.contains('mongo')) {
      buffer.writeln('  mongo_data:');
    }
    if (serviceList.contains('redis')) {
      buffer.writeln('  redis_data:');
    }

    // Add networks section
    buffer.writeln();
    buffer.writeln('networks:');
    buffer.writeln('  khadem-network:');
    buffer.writeln('    driver: bridge');

    return buffer.toString();
  }

  Future<void> _prepareSourceDeployment() async {
    logger.info(' Preparing source-only deployment...');

    final archive = Archive();

    // Add all source files except build artifacts and dev files
    final excludePatterns = [
      RegExp(r'\.git'),
      RegExp(r'build/'),
      RegExp(r'\.dart_tool/'),
      RegExp(r'pubspec\.lock'),
      RegExp(r'\.log$'),
      RegExp(r'\.md$'),
      RegExp(r'docs/'),
      RegExp(r'test/'),
      RegExp(r'\.vscode/'),
      RegExp(r'\.idea/'),
    ];

    await for (var entity in Directory('.').list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path);
        final shouldExclude = excludePatterns.any((pattern) => pattern.hasMatch(relativePath));

        if (!shouldExclude) {
          final bytes = await entity.readAsBytes();
          final archiveFile = ArchiveFile(relativePath.replaceAll('\\', '/'), bytes.length, bytes);
          archive.addFile(archiveFile);
          if (argResults?['verbose'] == true) {
            logger.info(' Added to source archive: ');
          }
        }
      }
    }

    // Create the tar.gz file
    final gzipData = GZipEncoder().encode(TarEncoder().encode(archive))!;
    const archivePath = 'build/source-deploy.tar.gz';
    await Directory('build').create(recursive: true);
    final archiveFile = File(archivePath);
    await archiveFile.writeAsBytes(gzipData);

    logger.info(' Source deployment archive created: ');
    logger.info(' Deploy instructions:');
    logger.info('   1. Extract archive on Linux server');
    logger.info('   2. Run: dart pub get');
    logger.info('   3. Run: dart compile exe bin/server.dart -o bin/server');
    logger.info('   4. Start: ./bin/server');
  }

  @override
  Future<void> handle(List<String> args) async {
    final String output = argResults?['output'] as String? ?? 'bin/server.exe';
    final useAOT = argResults?['aot'] as bool? ?? false;
    final createArchive = argResults?['archive'] as bool? ?? false;
    final generateDocker = argResults?['docker'] as bool? ?? false;
    final sourceDeploy = argResults?['source-deploy'] as bool? ?? false;
    final deleteTemp = argResults?['delete-temp'] as bool? ?? true;

    // Check if we're in a Khadem project (has server.dart) - skip for Docker generation
    if (!generateDocker) {
      final serverFile = File('bin/server.dart');
      if (!await serverFile.exists()) {
        logger.error(' Error: bin/server.dart not found. Are you in a Khadem project directory?');
        logger.info(' Tip: Run this command from a Khadem project created with "khadem new"');
        exit(1);
      }
    }

    // Handle special deployment modes
    if (generateDocker) {
      await _generateDockerfile();
      final services = argResults?['services'] as String? ?? 'none';
      if (services != 'none') {
        logger.info(' Docker setup complete! Run: docker-compose up -d');
        logger.info(' Services included: $services');
        logger.info(' Make sure to copy .env.example to .env and configure your environment variables');
      } else {
        logger.info(' Docker setup complete! Run: docker build -t myapp . && docker run -p 9000:9000 myapp');
      }
      return;
    }

    if (sourceDeploy) {
      await _prepareSourceDeployment();
      return;
    }

    // Ensure output directory exists
    final outputFile = File(output);
    await outputFile.parent.create(recursive: true);

    final compileType = useAOT ? 'AOT executable' : 'JIT snapshot';
    logger.info('🛠️ Compiling project to $compileType...');

    final stopwatch = Stopwatch()..start();

    try {
      final compileArgs = useAOT
          ? [
              'compile',
              'exe',
              'bin/server.dart',
              '-o',
              output,
              '--obfuscate',
            ]
          : [
              'compile',
              'jit-snapshot',
              'bin/server.dart',
              '-o',
              output,
              '--obfuscate',
            ];

      final compile = await Process.run(
        'dart',
        compileArgs,
        environment: {
          'KHADIM_JIT_TRAINING': '1',
        },
      );

      if (compile.exitCode != 0) {
        logger.error('❌ Build failed: ${compile.stderr}');
        exit(1);
      }

      stopwatch.stop();
      logger.info('✅ $compileType created in ${stopwatch.elapsed.inSeconds}s: $output');

      if (createArchive) {
        logger.info('📦 Creating archive...');

        final archive = Archive();

        // Add the executable/snapshot
        final executableName = useAOT ? 'bin/server.exe' : 'bin/server.jit';
        await _addFileToArchiveIfExists(archive, output, executableName);

        // Add .env if exists
        await _addFileToArchiveIfExists(archive, '.env', '.env');

        // Add config JSON files
        final configDir = Directory('config');
        if (await configDir.exists()) {
          await _addDirectoryToArchive(archive, configDir, 'config');
        }

        // Add public directory
        final publicDir = Directory('public');
        if (await publicDir.exists()) {
          await _addDirectoryToArchive(archive, publicDir, 'public');
        }

        // Add storage directory
        final storageDir = Directory('storage');
        if (await storageDir.exists()) {
          await _addDirectoryToArchive(archive, storageDir, 'storage');
        }

        // Create the tar.gz file
        final gzipData = GZipEncoder().encode(TarEncoder().encode(archive))!;

        final archiveName = path.basenameWithoutExtension(output);
        final archivePath = 'build/${archiveName}.tar.gz';
        await Directory('build').create(recursive: true);
        final archiveFile = File(archivePath);
        await archiveFile.writeAsBytes(gzipData);

        logger.info('✅ Archive created: $archivePath');

        // Clean up temp files if requested
        if (deleteTemp) {
          // No temp dir created in this version, so nothing to delete
        }
      }

      logger.info('🎯 Build process finished successfully');
      logger.info('💡 Production tips:');
      if (useAOT) {
        logger.info('   • AOT executable is standalone - no Dart VM needed');
        logger.info('   • Better startup performance and memory usage');
        logger.info('   • Cross-platform deployment: Use Docker or source deployment');
      } else {
        logger.info('   • JIT snapshot requires Dart VM in production');
        logger.info('   • Consider using --aot for better performance');
        logger.info('   • Cross-platform deployment: Use --docker or --source-deploy');
      }
    } catch (e) {
      logger.error('❌ Build failed with error: $e');
      exit(1);
    }
  }

  @override
  String get description =>
      'Build the project for production deployment with cross-platform options';

  @override
  String get name => 'build';
}

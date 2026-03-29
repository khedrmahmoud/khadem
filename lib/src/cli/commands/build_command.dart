import 'dart:async';
import 'dart:io';

import '../../contracts/cli/command.dart';

class BuildCommand extends KhademCommand {
  BuildCommand({required super.logger}) {
    argParser.addOption(
      'services',
      abbr: 'e',
      help:
          'Specify external services to include (mysql,redis,nginx,postgres,mongo,none)',
      defaultsTo: 'none',
    );
    argParser.addFlag(
      'delete-temp',
      abbr: 'd',
      defaultsTo: true,
      help: 'Delete temporary files after build',
    );
    argParser.addFlag('verbose', abbr: 'v', help: 'Enable verbose logging');
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

# Ensure required directories exist so COPY doesn't fail
RUN mkdir -p config public storage/database storage/logs lang resources bin

# Compile to kernel snapshot (AOT does not support dart:mirrors)       
RUN dart compile kernel lib/main.dart -o bin/server.dill

# Production stage
FROM dart:stable

# Install ca-certificates and curl for HTTPS connections and health checks, and libsqlite3-dev for SQLite support
RUN apt-get update && apt-get install -y ca-certificates curl libsqlite3-dev && rm -rf /var/lib/apt/lists/* || true


# Create non-root user
RUN groupadd -r appgroup && useradd -m -r -g appgroup -s /bin/bash app

WORKDIR /app

# Ensure directories exist and are owned by app user
RUN mkdir -p config public storage/database storage/logs lang resources && chown -R app:appgroup /app

# Switch to the non-root user
USER app

# Copy application kernel snapshot
COPY --from=build --chown=app:appgroup /app/bin/server.dill /app/bin/server.dill

# Copy application files (directories only, inject env via docker run/compose)
COPY --from=build --chown=app:appgroup /app/config/ ./config/
COPY --from=build --chown=app:appgroup /app/public/ ./public/
COPY --from=build --chown=app:appgroup /app/storage/ ./storage/
COPY --from=build --chown=app:appgroup /app/lang/ ./lang/
COPY --from=build --chown=app:appgroup /app/resources/ ./resources/

EXPOSE 9000
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\
  CMD curl -f http://localhost:9000/health || exit 1

CMD ["dart", "run", "/app/bin/server.dill"]
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
.env
''';

    await File('.dockerignore').writeAsString(dockerignore);
    logger.info('📝 Generated .dockerignore file');
  }

  Future<String> _generateDockerCompose(String services) async {
    final serviceList = services
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .toList();
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
    if (serviceList.contains('mysql') ||
        serviceList.contains('postgres') ||
        serviceList.contains('mongo')) {
      dependsOn.add('database');
    }
    if (serviceList.contains('redis')) {
      dependsOn.add('redis');
    }

    // Add depends_on if there are dependencies
    if (dependsOn.isNotEmpty) {
      buffer.writeln('    depends_on:');
      for (final dep in dependsOn) {
        buffer.writeln('      $dep:');
        buffer.writeln('        condition: service_healthy');
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
      buffer.writeln(
        '      - MYSQL_ROOT_PASSWORD=${r'$'}{DB_PASSWORD:-root_password}',
      );
      buffer.writeln('      - MYSQL_DATABASE=${r'$'}{DB_DATABASE:-khadem_db}');
      buffer.writeln('      - MYSQL_USER=${r'$'}{DB_USER:-khadem_user}');
      buffer.writeln(
        '      - MYSQL_PASSWORD=${r'$'}{DB_PASSWORD:-your_password}',
      );
      buffer.writeln('    ports:');
      buffer.writeln('      - "${r'$'}{DB_PORT:-3306}:3306"');
      buffer.writeln('    volumes:');
      buffer.writeln('      - mysql_data:/var/lib/mysql');
      buffer.writeln(
        '    command: --default-authentication-plugin=mysql_native_password',
      );
      buffer.writeln('    healthcheck:');
      buffer.writeln(
        '      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]',
      );
      buffer.writeln('      timeout: 20s');
      buffer.writeln('      retries: 5');
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
      buffer.writeln('      - POSTGRES_DB=${r'$'}{DB_DATABASE:-khadem_db}');
      buffer.writeln('      - POSTGRES_USER=${r'$'}{DB_USER:-khadem_user}');
      buffer.writeln(
        '      - POSTGRES_PASSWORD=${r'$'}{DB_PASSWORD:-your_password}',
      );
      buffer.writeln('    ports:');
      buffer.writeln('      - "${r'$'}{DB_PORT:-5432}:5432"');
      buffer.writeln('    volumes:');
      buffer.writeln('      - postgres_data:/var/lib/postgresql/data');
      buffer.writeln('    healthcheck:');
      buffer.writeln(
        '      test: ["CMD-SHELL", "pg_isready -U ${r'$'}{DB_USER:-khadem_user} -d ${r'$'}{DB_DATABASE:-khadem_db}"]',
      );
      buffer.writeln('      interval: 10s');
      buffer.writeln('      timeout: 5s');
      buffer.writeln('      retries: 5');
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
      buffer.writeln(
        '      - MONGO_INITDB_DATABASE=${r'$'}{DB_DATABASE:-khadem_db}',
      );
      buffer.writeln('    ports:');
      buffer.writeln('      - "${r'$'}{DB_PORT:-27017}:27017"');
      buffer.writeln('    volumes:');
      buffer.writeln('      - mongo_data:/data/db');
      buffer.writeln('    healthcheck:');
      buffer.writeln(
        '      test: echo "db.runCommand(\\"ping\\").ok" | mongosh localhost:27017/test --quiet',
      );
      buffer.writeln('      interval: 10s');
      buffer.writeln('      timeout: 5s');
      buffer.writeln('      retries: 5');
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
      buffer.writeln(
        '    command: redis-server --requirepass ${r'$'}{REDIS_PASSWORD:-}',
      );
      buffer.writeln('    healthcheck:');
      buffer.writeln('      test: ["CMD", "redis-cli", "ping"]');
      buffer.writeln('      interval: 10s');
      buffer.writeln('      timeout: 5s');
      buffer.writeln('      retries: 5');
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

  @override
  Future<void> handle(List<String> args) async {
    await _generateDockerfile();
    final services = argResults?['services'] as String? ?? 'none';
    if (services != 'none') {
      logger.info(' Docker setup complete! Run: docker-compose up -d');
      logger.info(' Services included: $services');
      logger.info(
        ' Make sure to copy .env.example to .env and configure your environment variables',
      );
    } else {
      logger.info(
        ' Docker setup complete! Run: docker build -t myapp . && docker run -p 9000:9000 myapp',
      );
    }
  }

  @override
  String get description => 'Generate Docker setup for production deployment';

  @override
  String get name => 'build';
}

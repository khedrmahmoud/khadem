import 'dart:io';

import 'package:khadem/khadem.dart'
    show
        ServiceProvider,
        ContainerInterface,
        EnvInterface,
        EnvSystem,
        ConfigInterface,
        ConfigSystem,
        Logger,
        DatabaseManager,
        Migrator,
        SeederManager,
        QueueManager,
        ConsoleLogHandler;

/// A lightweight service provider for CLI-only context.
/// Does not start servers or workers, just logging + database + migrator.
class CliServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    // Minimal config and logging

    final configPath = _resolveConfigPath();

    container.lazySingleton<EnvInterface>((c) => EnvSystem());
    container.singleton<ConfigInterface>(
      (c) => ConfigSystem(
        configPath: configPath,
        environment:
            c.resolve<EnvInterface>().getOrDefault('APP_ENV', 'development'),
      ),
    );

    container.lazySingleton<Logger>(
      (c) => Logger()..addHandler(ConsoleLogHandler()),
    );

    // Optional: Database + Migrator + Seeder (only CLI tools)
    container.lazySingleton<DatabaseManager>(
      (c) => DatabaseManager(c.resolve<ConfigInterface>()),
    );
    container
        .lazySingleton<Migrator>((c) => Migrator(c.resolve<DatabaseManager>()));
    container.lazySingleton<SeederManager>((c) => SeederManager());
    container.lazySingleton<QueueManager>(
      (c) => QueueManager(c.resolve<ConfigInterface>()),
    );
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    final envSystem = container.resolve<EnvInterface>();
    envSystem.loadFromFile('.env');

    final config = container.resolve<ConfigInterface>() as ConfigSystem;
    config.setEnvironment(envSystem.getOrDefault('APP_ENV', 'development'));

    final logger = container.resolve<Logger>();
    final queue = container.resolve<QueueManager>();

    _ensureDatabaseConfigFromEnv(envSystem, config);

    try {
      queue.loadFromConfig();
    } catch (e) {
      logger.warning(
        '⚠️ Queue not configured. Queue-related commands may fail. ($e)',
      );
    }

    logger.info('✅ CLI services initialized');
  }

  void _ensureDatabaseConfigFromEnv(
    EnvInterface env,
    ConfigInterface config,
  ) {
    final driver = env.getOrDefault('DB_CONNECTION', 'mysql');

    final existing =
        config.get<Map<String, dynamic>>('database.connections.$driver');
    if (existing != null) {
      return;
    }

    config.set('database.default', driver);

    switch (driver) {
      case 'sqlite':
        config.set(
          'database.connections.sqlite',
          <String, dynamic>{
            'driver': 'sqlite',
            'path': env.getOrDefault('DB_DATABASE', 'storage/database.sqlite'),
          },
        );
        return;

      case 'mysql':
      default:
        config.set(
          'database.connections.mysql',
          <String, dynamic>{
            'driver': 'mysql',
            'host': env.getOrDefault('DB_HOST', '127.0.0.1'),
            'port': env.getInt('DB_PORT', defaultValue: 3306),
            'database': env.getOrDefault('DB_DATABASE', 'khadem'),
            'username': env.getOrDefault('DB_USERNAME', 'root'),
            'password': env.getOrDefault('DB_PASSWORD', ''),
          },
        );
        return;
    }
  }

  String _resolveConfigPath() {
    const primary = 'config';
    if (Directory(primary).existsSync()) {
      return primary;
    }

    const examplePath = 'example/config';
    if (Directory(examplePath).existsSync()) {
      return examplePath;
    }

    return primary;
  }
}

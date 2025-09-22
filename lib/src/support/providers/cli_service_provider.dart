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

    container.lazySingleton<EnvInterface>((c) => EnvSystem());
    container.singleton<ConfigInterface>(
      (c) => ConfigSystem(
        configPath: 'config',
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

    final database = container.resolve<DatabaseManager>();
    final queue = container.resolve<QueueManager>();

    await database.init();
    queue.loadFromConfig();
    container.resolve<Logger>().info('✅ CLI services initialized');
  }
}

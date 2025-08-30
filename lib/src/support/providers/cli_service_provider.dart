import '../../contracts/config/config_contract.dart';
import '../../contracts/container/container_interface.dart';
import '../../contracts/env/env_interface.dart';
import '../../contracts/provider/service_provider.dart';
import '../../core/config/config_system.dart';
import '../../core/config/env_system.dart';
import '../../core/database/database.dart';
import '../../core/database/migration/migrator.dart';
import '../../core/database/migration/seeder.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/queue/queue_manager.dart';
import '../logging_writers/console_writer.dart';

/// A lightweight service provider for CLI-only context.
/// Does not start servers or workers, just logging + database + migrator.
class CliServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    // Minimal config and logging
    container.lazySingleton<EnvInterface>((c) => EnvSystem());
    container.singleton<ConfigInterface>((c) => ConfigSystem(
          configPath: 'config',
          environment:
              c.resolve<EnvInterface>().getOrDefault('APP_ENV', 'development'),
        ),);

    container.lazySingleton<Logger>(
        (c) => Logger()..addHandler(ConsoleLogHandler()),);

    // Optional: Database + Migrator + Seeder (only CLI tools)
    container.lazySingleton<DatabaseManager>(
        (c) => DatabaseManager(c.resolve<ConfigInterface>()),);
    container
        .lazySingleton<Migrator>((c) => Migrator(c.resolve<DatabaseManager>()));
    container.lazySingleton<SeederManager>((c) => SeederManager());
    container.lazySingleton<QueueManager>(
      (c) => QueueManager(c.resolve<ConfigInterface>()),
    );
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    container.resolve<EnvInterface>().loadFromFile('.env');
    final database = container.resolve<DatabaseManager>();
    final queue = container.resolve<QueueManager>();

    await database.init();
    await queue.init();
    container.resolve<Logger>().info('✅ CLI services initialized');
  }
}

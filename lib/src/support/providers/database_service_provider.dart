import 'package:khadem/khadem.dart'
    show Khadem;

import '../../contracts/config/config_contract.dart';
import '../../contracts/container/container_interface.dart';
import '../../contracts/provider/service_provider.dart';
import '../../core/database/database.dart';
import '../../core/database/migration/migrator.dart';
import '../../core/database/migration/seeder.dart';

/// Database service provider that handles database connections,
/// migrations, and seeders.
class DatabaseServiceProvider extends ServiceProvider {
  @override
  bool get isDeferred => true;

  @override
  List<Type> get provides => [DatabaseManager, Migrator, SeederManager];

  @override
  void register(ContainerInterface container) {
    // Register the Database Manager
    container.lazySingleton<DatabaseManager>(
      (c) => DatabaseManager(c.resolve<ConfigInterface>()),
    );

    // Register the Migrator
    container
        .lazySingleton<Migrator>((c) => Migrator(c.resolve<DatabaseManager>()));

    // Register the Seeder Manager
    container.lazySingleton<SeederManager>((c) => SeederManager());
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    final database = container.resolve<DatabaseManager>();
    final config = Khadem.config;

    await database.init();

    if (config.get<bool>('database.run_migrations', false)!) {
      await Khadem.migrator.upAll();
    }

    if (config.get<bool>('database.run_seeders', false)!) {
      await Khadem.seeder.runAll();
    }
  }
}

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

    await database.init();
  }
}

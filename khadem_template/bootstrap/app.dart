import 'package:khadem/khadem_dart.dart' show Khadem, ContainerInterface;

import '../core/kernel.dart';

/// Bootstraps the application.
///
/// Used for minimal startup in `main()`.
Future<void> bootstrap(ContainerInterface container) async {
  // 🧠 Initialize Khadem core with optional light mode
  await Khadem.registerCoreServices();

  // 🔌 Register the config registry (static Dart maps)
  Khadem.loadConfigs(Kernel.configs);

  // 📦 Register the services
  Khadem.register(Kernel.providers);

  await Khadem.boot();
}

Future<void> lazyBootStrap() async {
  final config = Khadem.config;
  // 📦 Register the lazy providers
  Khadem.register(Kernel.lazyProviders);

  // 📦 Register the DB migrations
  Khadem.migrator.registerAll(Kernel.migrations);

  // 📦 Register the DB seeders
  Khadem.seeder.registerAll([]);

  if (config.get<bool>('database.run_migrations', false)!) {
    await Khadem.migrator.upAll();
  }

  if (config.get<bool>('database.run_seeders', false)!) {
    await Khadem.seeder.runAll();
  }
}

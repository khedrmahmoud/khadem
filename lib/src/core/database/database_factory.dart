

import '../../contracts/config/config_contract.dart';
import '../../contracts/database/database_factory_interface.dart';
import '../../support/exceptions/database_exception.dart';
import 'database_drivers/mysql/mysql_driver.dart';

/// Central registry for all supported database factories.
///
/// Dynamically selects the appropriate factory based on the configuration.
class DatabaseFactory {
  static final Map<String, DatabaseFactoryInterface> _factories = {
    'mysql': MySQLDriver(),
    // 'postgresql': PostgreSQLDriver(),  // To be added later
    // 'sqlite': SQLiteDriver(),         // To be added later
  };

  /// Resolves and returns the appropriate factory based on config.
  static (DatabaseFactoryInterface, String) resolve(ConfigInterface config) {
    final defaultDriver = config.get<String>('database.default', 'mysql');
    final factory = _factories[defaultDriver];
    if (factory == null) {
      throw DatabaseException('Database driver [$defaultDriver] not supported');
    }
    return (factory, defaultDriver!);
  }

  /// Registers a custom driver (for external extensions).
  static void register(String name, DatabaseFactoryInterface factory) {
    _factories[name] = factory;
  }
}

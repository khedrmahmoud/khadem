import '../../contracts/config/config_contract.dart';
import 'queue_driver.dart';
import 'queue_driver_registry.dart';

/// Interface for queue configuration loading.
/// Defines the contract for loading and parsing queue configuration.
abstract class IQueueConfigLoader {
  /// Loads queue configuration and registers drivers.
  /// Throws [QueueException] if configuration is invalid.
  void loadFromConfig(ConfigInterface config, IQueueDriverRegistry registry);

  /// Creates a queue driver instance from configuration.
  /// Throws [QueueException] if driver type is unknown or configuration is invalid.
  QueueDriver createDriverFromConfig(
    String driverType,
    Map<String, dynamic> settings,
  );
}

import '../../contracts/config/config_contract.dart';
import '../../contracts/queue/queue_driver.dart';
import '../../support/exceptions/queue_exception.dart';
 import '../../support/queue_drivers/file_queue_driver.dart';
import '../../support/queue_drivers/memory_queue_driver.dart';
import '../../support/queue_drivers/redis_queue_driver.dart';
import '../../support/queue_drivers/sync_queue_driver.dart';
import 'queue_driver_registry.dart';

/// Simplified queue factory for Laravel-style queues
/// Focuses on core functionality without serialization complexity.
class QueueFactory {
  static final QueueFactory _instance = QueueFactory._();
  final QueueDriverRegistry _registry;

  static QueueFactory get instance => _instance;

  QueueFactory._()
      : _registry = QueueDriverRegistry() {
    _registerDefaultDrivers();
  }

  /// Gets the driver registry for external access.
  QueueDriverRegistry get registry => _registry;

  /// Registers a custom queue driver.
  static void registerDriver(String name, QueueDriver driver) {
    _instance._registry.register(name, driver);
  }

  /// Resolves a queue driver from configuration.
  static (QueueDriver, String) resolve(ConfigInterface config) {
    final defaultDriverName = config.get<String>('queue.driver', 'memory')!;
    final driver = _instance._registry.getDriver(defaultDriverName);

    if (driver == null) {
      throw QueueException(
        'Queue driver not found: $defaultDriverName. '
        'Available drivers: ${_instance._registry.getDriverNames()}'
      );
    }

    return (driver, defaultDriverName);
  }

  /// Registers the default queue drivers.
  void _registerDefaultDrivers() {
    _registry.register('sync', SyncQueueDriver());
    _registry.register('memory', MemoryQueueDriver());
    // File and Redis drivers work but execute immediately (no serialization)
    _registry.register('file', FileQueueDriver());
    _registry.register('redis', RedisQueueDriver());
  }
}

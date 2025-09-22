import 'package:khadem/src/contracts/config/config_contract.dart';
import 'package:khadem/src/contracts/queue/queue_config_loader.dart';
import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/contracts/queue/queue_driver_registry.dart';
import 'package:khadem/src/support/exceptions/queue_exception.dart';
import '../queue_drivers/file_queue_driver.dart';
import '../queue_drivers/memory_queue_driver.dart';
import '../queue_drivers/redis_queue_driver.dart';
import '../queue_drivers/sync_queue_driver.dart';

/// Implementation of queue configuration loader.
/// Handles loading queue configuration and initializing drivers.
class QueueConfigLoader implements IQueueConfigLoader {
  @override
  void loadFromConfig(ConfigInterface config, IQueueDriverRegistry registry) {
    try {
      final driverConfigs = config.get<Map>('queue.drivers') ?? {};
      final defaultDriverName = config.get<String>('queue.default') ?? 'memory';

      // Load all configured drivers
      driverConfigs.forEach((name, settings) {
        final driver = createDriverFromConfig(
          settings['driver'] as String? ?? 'memory',
          settings as Map<String, dynamic>,
        );
        registry.registerDriver(name as String, driver);
      });

      // Register default memory driver if no drivers configured
      if (registry.getDriverNames().isEmpty) {
        registry.registerDriver('memory', MemoryQueueDriver());
      }

      // Set default driver
      registry.setDefaultDriver(defaultDriverName);
    } catch (e) {
      throw QueueException('Failed to load queue configuration: $e');
    }
  }

  @override
  QueueDriver createDriverFromConfig(
    String driverType,
    Map<String, dynamic> settings,
  ) {
    switch (driverType.toLowerCase()) {
      case 'memory':
        return MemoryQueueDriver();

      case 'sync':
        return SyncQueueDriver();

      case 'file':
        final path = settings['path'] as String?;
        if (path != null && path.isNotEmpty) {
          return FileQueueDriver(queuePath: path);
        }
        return FileQueueDriver();

      case 'redis':
        final host = settings['host'] as String? ?? 'localhost';
        final port = settings['port'] as int? ?? 6379;
        final password = settings['password'] as String?;
        final queueName = settings['queue_name'] as String? ?? 'default';

        return RedisQueueDriver(
          queueName: queueName,
          host: host,
          port: port,
          password: password,
        );

      default:
        throw QueueException('Unknown queue driver: $driverType');
    }
  }
}

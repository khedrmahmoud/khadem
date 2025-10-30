import 'package:khadem/src/contracts/config/config_contract.dart';
import 'package:khadem/src/contracts/queue/queue_config_loader.dart';
import 'package:khadem/src/contracts/queue/queue_driver.dart';
import 'package:khadem/src/contracts/queue/queue_driver_registry.dart';
import 'package:khadem/src/support/exceptions/queue_exception.dart';

import '../drivers/base_driver.dart';
import '../drivers/file_storage_driver.dart';
import '../drivers/in_memory_driver.dart';
import '../drivers/redis_storage_driver.dart';
import '../drivers/synchronous_driver.dart';

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
        registry.registerDriver(
          'memory',
          InMemoryDriver(config: const DriverConfig(name: 'memory')),
        );
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
    final driverName = settings['name'] as String? ?? driverType;
    final trackMetrics = settings['track_metrics'] as bool? ?? true;
    final useDLQ = settings['use_dlq'] as bool? ?? true;
    final maxRetries = settings['max_retries'] as int? ?? 3;
    final timeout = settings['timeout'] as int?;

    final config = DriverConfig(
      name: driverName,
      trackMetrics: trackMetrics,
      useDLQ: useDLQ,
      maxRetries: maxRetries,
      defaultJobTimeout: timeout != null ? Duration(seconds: timeout) : null,
    );

    switch (driverType.toLowerCase()) {
      case 'memory':
      case 'in_memory':
        return InMemoryDriver(config: config);

      case 'sync':
      case 'synchronous':
        return SynchronousDriver(config: config);

      case 'file':
      case 'file_storage':
        final path = settings['path'] as String? ?? './storage/queue';
        return FileStorageDriver(
          config: config,
          storagePath: path,
        );

      case 'redis':
      case 'redis_storage':
        final host = settings['host'] as String? ?? 'localhost';
        final port = settings['port'] as int? ?? 6379;
        final password = settings['password'] as String?;
        final queueName = settings['queue_name'] as String? ?? config.name;

        return RedisStorageDriver(
          config: config,
          host: host,
          port: port,
          password: password,
          queueName: queueName,
        );

      default:
        throw QueueException('Unknown queue driver: $driverType');
    }
  }
}

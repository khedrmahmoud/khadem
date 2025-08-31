import '../../contracts/config/config_contract.dart';
import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';
import '../../support/exceptions/queue_exception.dart';
import '../../support/queue_drivers/file_queue_driver.dart';
import '../../support/queue_drivers/memory_queue_driver.dart';
import '../../support/queue_drivers/redis_queue_driver.dart';
import '../../support/queue_drivers/sync_queue_driver.dart';
import 'queue_driver_registry.dart';
import 'queue_job_serializer.dart';

/// Enhanced queue factory with separated concerns.
/// Manages driver registration and resolution while delegating
/// serialization to dedicated components.
class QueueFactory {
  static final QueueFactory _instance = QueueFactory._();
  final QueueDriverRegistry _registry;
  final QueueJobSerializer _serializer;

  static QueueFactory get instance => _instance;

  QueueFactory._()
      : _registry = QueueDriverRegistry(),
        _serializer = QueueJobSerializer() {
    _registerDefaultDrivers();
  }

  /// Gets the driver registry for external access.
  QueueDriverRegistry get registry => _registry;

  /// Gets the job serializer for external access.
  QueueJobSerializer get serializer => _serializer;

  /// Registers a custom queue driver.
  static void registerDriver(String name, QueueDriver driver) {
    _instance._registry.register(name, driver);
  }

  /// Resolves a queue driver from configuration.
  static (QueueDriver, String) resolve(ConfigInterface config) {
    final defaultDriverName = config.get<String>('queue.driver', 'sync')!;
    final driver = _instance._registry.getDriver(defaultDriverName);

    if (driver == null) {
      throw QueueException(
        'Queue driver not found: $defaultDriverName. '
        'Available drivers: ${_instance._registry.getDriverNames()}'
      );
    }

    return (driver, defaultDriverName);
  }

  /// Registers a job factory for deserialization.
  static void registerJobFactory(String type, QueueJobFactory factory) {
    _instance._serializer.registerFactory(type, factory);
  }

  /// Serializes a job using the serializer.
  static Map<String, dynamic> serializeJob(QueueJob job) {
    return _instance._serializer.serialize(job);
  }

  /// Deserializes a job using the serializer.
  static QueueJob deserializeJob(Map<String, dynamic> json) {
    return _instance._serializer.deserialize(json);
  }

  /// Registers the default queue drivers.
  void _registerDefaultDrivers() {
    _registry.register('sync', SyncQueueDriver());
    _registry.register('memory', MemoryQueueDriver());
    _registry.register('file', FileQueueDriver());
    _registry.register('redis', RedisQueueDriver());
  }
}

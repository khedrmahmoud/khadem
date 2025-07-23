 import '../../contracts/config/config_contract.dart';
import '../../contracts/queue/queue_driver.dart';
import '../../support/queue_drivers/file_queue_driver.dart';
import '../../support/queue_drivers/memory_queue_driver.dart';
import '../../support/queue_drivers/redis_queue_driver.dart';
import '../../support/queue_drivers/sync_queue_driver.dart';
import '../../support/exceptions/queue_exception.dart';

class QueueFactory {
  static final QueueFactory instance = QueueFactory._();
  static final Map<String, QueueDriver> _drivers = {
    'sync': SyncQueueDriver(),
    'memory': MemoryQueueDriver(),
    'file': FileQueueDriver(),
    'redis': RedisQueueDriver(),
  };

  QueueFactory._();

  static void register(String name, QueueDriver driver) {
    _drivers[name] = driver;
  }

  static (QueueDriver, String) resolve(ConfigInterface config) {
    final defaultDriverName = config.get<String>('queue.driver', 'sync')!;
    final driver = _drivers[defaultDriverName];
    if (driver == null) {
      throw QueueException('Queue driver not found: $defaultDriverName');
    }
    return (driver, defaultDriverName);
  }
}

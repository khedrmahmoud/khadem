import '../../contracts/queue/queue_job.dart';

typedef QueueJobFactory = QueueJob Function(Map<String, dynamic> json);

class QueueJobRegistry {
  static final Map<String, QueueJobFactory> _factories = {};

  static void register(String type, QueueJobFactory factory) {
    _factories[type] = factory;
  }

  static QueueJob fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final factory = _factories[type];
    if (factory == null) {
      throw Exception('No factory registered for job type: $type');
    }
    return factory(json);
  }
}

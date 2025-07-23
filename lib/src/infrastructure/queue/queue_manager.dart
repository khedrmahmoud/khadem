 import '../../contracts/config/config_contract.dart';
import '../../contracts/queue/queue_driver.dart';
import '../../contracts/queue/queue_job.dart';
import 'queue_factory.dart';

class QueueManager {
  late QueueDriver _default;
  late String _defaultDriverName;
  final ConfigInterface _config;

  QueueManager(this._config);

  /// Initializes the connection.
  Future<void> init() async {
    final (defaultDriver, defaultDriverName) = QueueFactory.resolve(_config);
    _default = defaultDriver;
    _defaultDriverName = defaultDriverName;
  }

  QueueDriver get driver => _default;
  String get defaultDriverName => _defaultDriverName;

  Future<void> dispatch(QueueJob job, {Duration? delay}) {
    return _default.push(job, delay: delay);
  }

  Future<void> process() {
    return _default.process();
  }

  Future<void> startWorker({
    int? maxJobs,
    Duration delay = const Duration(seconds: 1),
    Duration? timeout,
    bool runInBackground = false,
    void Function(dynamic error, StackTrace stack)? onError,
  }) async {
    int processed = 0;
    final start = DateTime.now();
    bool running = true;

    workerLogic() async {
      while (running) {
        try {
          await _default.process();
          processed++;

          if (maxJobs != null && processed >= maxJobs) {
            running = false;
            break;
          }

          if (timeout != null && DateTime.now().difference(start) >= timeout) {
            running = false;
            break;
          }

          await Future.delayed(delay);
        } catch (e, stack) {
          onError?.call(e, stack);
        }
      }
    }

    if (runInBackground) {
      Future(workerLogic);
    } else {
      await workerLogic();
    }
  }
}

import 'package:khadem/contracts.dart' show ContainerInterface, ServiceProvider;
import 'package:khadem/scheduler.dart' show startSchedulers;

class SchedulerServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {}

  @override
  Future<void> boot(ContainerInterface container) async {
    // ✅ Start schedulers here
    startSchedulers(
      tasks: [], // You can provide scheduled tasks here
    );
  }
}

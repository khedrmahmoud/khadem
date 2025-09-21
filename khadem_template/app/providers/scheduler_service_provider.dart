import 'package:khadem/khadem.dart' show ServiceProvider, startSchedulers;

class SchedulerServiceProvider extends ServiceProvider {
  @override
  void register(container) {}

  @override
  Future<void> boot(container) async {
    // ✅ Start schedulers here
    startSchedulers();
  }
}

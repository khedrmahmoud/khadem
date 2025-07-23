import 'package:khadem/khadem_dart.dart' show ServiceProvider, startSchedulers;

class SchedulerServiceProvider extends ServiceProvider {
  @override
  void register(container) {}

  @override
  Future<void> boot(container) async {
    // ✅ Start schedulers here
    startSchedulers();
  }
}

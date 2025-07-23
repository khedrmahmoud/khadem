abstract class LifecycleHook {
  Future<void> onBoot() async {}
  Future<void> onShutdown() async {}
}

class LifecycleManager {
  static final List<LifecycleHook> _hooks = [];

  static void register(LifecycleHook hook) => _hooks.add(hook);

  static Future<void> bootAll() async {
    for (final hook in _hooks) {
      await hook.onBoot();
    }
  }

  static Future<void> shutdownAll() async {
    for (final hook in _hooks.reversed) {
      await hook.onShutdown();
    }
  }
}

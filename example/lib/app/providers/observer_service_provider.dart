import 'package:khadem/khadem.dart';
import '../models/user.dart';
import '../observers/user_observer.dart';

/// Service provider for registering model observers.
///
/// Observers provide a clean way to handle model lifecycle events
/// without cluttering model classes with business logic.
class ObserverServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {
    // Register UserObserver for User model
    HasEvents.observe<User>(UserObserver());
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    // Nothing to boot for observers
  }
}

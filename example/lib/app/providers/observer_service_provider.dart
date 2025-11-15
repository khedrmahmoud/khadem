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
    KhademModel.observe<User>(UserObserver());

    // You can register multiple observers for the same model
    // KhademModel.observe<User>(UserAuditObserver());
    // KhademModel.observe<User>(UserCacheObserver());

    // Register observers for other models
    // KhademModel.observe<Post>(PostObserver());
    // KhademModel.observe<Order>(OrderObserver());
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    // Nothing to boot for observers
  }
}

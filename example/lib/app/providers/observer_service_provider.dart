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
    // Register observers for models
    print('📋 Registering Model Observers...');
    
    // Register UserObserver for User model
    KhademModel.observe<User>(UserObserver());
    print('   ✓ UserObserver registered');
    
    // You can register multiple observers for the same model
    // KhademModel.observe<User>(UserAuditObserver());
    // KhademModel.observe<User>(UserCacheObserver());
    
    // Register observers for other models
    // KhademModel.observe<Post>(PostObserver());
    // KhademModel.observe<Order>(OrderObserver());
    
    print('✅ Model Observers registered successfully!');
  }

  @override
  Future<void> boot(ContainerInterface container) async {
    // Nothing to boot for observers
  }
}

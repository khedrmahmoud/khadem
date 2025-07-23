import '../../../contracts/container/container_interface.dart';
import '../../../contracts/provider/service_provider.dart';
import '../services/auth_manager.dart';

class AuthServiceProvider extends ServiceProvider {
  @override
  Future<void> register(ContainerInterface container) async {
    container.bind<AuthManager>((_) => AuthManager());
  }

  @override
  Future<void> boot(ContainerInterface container) async {}
}

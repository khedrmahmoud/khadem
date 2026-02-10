import 'package:khadem/contracts.dart' show ContainerInterface, ServiceProvider;

class AppServiceProvider extends ServiceProvider {
  @override
  void register(ContainerInterface container) {}

  @override
  Future<void> boot(ContainerInterface container) async {}
}

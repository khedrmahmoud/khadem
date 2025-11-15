import 'package:khadem/khadem.dart';
import '../app/http/controllers/home_controller.dart';

void registerRoutes(ServerRouter routeManager) {
// ✅ Web routes
  routeManager.get('/', HomeController.welcome);
  routeManager.get('/home', HomeController.index);
  routeManager.get('/stream', HomeController.stream);
}

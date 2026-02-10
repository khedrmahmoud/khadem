import 'package:khadem/routing.dart' show Router;
import '../app/http/controllers/home_controller.dart';

void registerRoutes(Router router) {
// ✅ Web routes
  router.get('/', HomeController.welcome);
  router.get('/home', HomeController.index);
  router.get('/stream', HomeController.stream);
}

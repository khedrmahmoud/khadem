import 'package:khadem/khadem_dart.dart';
import '../app/http/controllers/home_controller.dart';
import '../core/kernel.dart';

void registerRoutes(Server server) {
  // 🛡️Register global middlewares
  server.useMiddlewares(Kernel.middlewares);

  // 🏠 Home Routes
  server.group(
      prefix: '/home',
      middleware: [
        // Add any middlewares here
      ],
      routes: (router) async {
        router.get('', HomeController.index);
        router.get('/welcome', HomeController.welcome);
        // 🔁 Stream test route
        router.get('/stream', HomeController.stream);
      });
}

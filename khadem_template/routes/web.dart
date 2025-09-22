import 'package:khadem/khadem.dart';
import '../app/http/controllers/home_controller.dart';
import '../core/kernel.dart';

void registerRoutes(Server server) {
  // 🛡️Register global middlewares
  server.useMiddlewares(Kernel.middlewares);

  server.get('/', HomeController.welcome);

  server.get('/home', HomeController.index);

  // 🔁 Stream test route
  server.get('/stream', HomeController.stream);

  // Serve static files from 'public' directory
  server.serveStatic();
}

import 'package:khadem/khadem.dart';
import '../app/socket/controllers/chat_controller.dart';

void registerSocketRoutes(SocketServer server) {
  // Register Chat Controller
  server.registerController(ChatController());

  // Global events (no namespace)
  server.on('ping', (context) {
    context.emit('pong', {'message': 'pong', 'received': context.data});
  });
}

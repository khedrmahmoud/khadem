import 'package:khadem/khadem.dart';

void registerSocketRoutes(SocketServer server) {
  // ✅ Event-specific handlers
  server.on('ping', (client, data) {
    client.send('pong', {'message': 'pong'});
  });
}

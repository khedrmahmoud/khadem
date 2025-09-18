import 'package:khadem/khadem_dart.dart';

void registerSocketRoutes(SocketServer server) {
  // ✅ Event-specific handlers
  server.on('ping', (client, data) {
    client.send('pong', {'message': 'pong'});
  });
}

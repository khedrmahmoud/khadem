import 'package:khadem/khadem.dart';

void registerSocketRoutes(SocketServer server) {
  // Socket event: ping
  server.on('ping', (client, data) {
    client.send('pong', {'message': 'pong'});
  });
}

import 'package:khadem/socket.dart' show SocketServer;

void registerSocketRoutes(SocketServer server) {
  // Socket event: ping
  server.on('ping', (context) {
    context.emit('pong', {'message': 'pong'});
  });
}

import 'dart:async';

import 'package:khadem/khadem.dart'
    show Khadem, ContainerInterface, SocketServer, Server, SocketManager;

import '../core/kernel.dart';
import '../routes/socket.dart';
import '../routes/web.dart';

/// Entry point of the Khadem application.
/// Initializes the application kernel, starts the HTTP and Socket servers.
Future<void> main(List<String> args) async {
  final container = Khadem.container;
  // Bootstrap the application kernel
  await Kernel.bootstrap();

  // Start both HTTP and Socket servers concurrently
  await Future.wait([
    _startHttpServer(container),
    _startSocketServer(container, Khadem.socket),
  ]);
}

/// Start the HTTP server
Future _startHttpServer(ContainerInterface container) async {
  final port = _extractPort("http_port");
  final server = Server();

  // Register global middlewares
  server.applyMiddlewares(Kernel.middlewares);
  // Inject web routes
  server.injectRoutes(registerRoutes);
  // Serve static files from `public` folder
  server.serveStatic();

  await server.start(port: port);
}

/// Start the Socket server
Future<void> _startSocketServer(
  ContainerInterface container,
  SocketManager manager,
) async {
  final socketPort = _extractPort("socket_port", defaultValue: 8080);
  final socketServer = SocketServer(socketPort, manager: manager);
  // Inject socket routes
  registerSocketRoutes(socketServer);

  await socketServer.start();
}

/// Extract port from environment
int _extractPort(String varName, {int defaultValue = 9000}) {
  return Khadem.config.get("app.$varName") ?? defaultValue;
}

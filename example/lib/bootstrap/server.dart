import 'dart:async';

import 'package:khadem/http.dart';
import 'package:khadem/khadem.dart';
import 'package:khadem/socket.dart' show SocketServer, SocketConfig;

import '../routes/socket.dart';
import '../routes/web.dart';
import 'kernel.dart';
import 'ports.dart';

/// Runs the application (used by `lib/main.dart` and optional `bin/server.dart`).
Future<void> run(List<String> args) async {
  await Kernel.bootstrap();

  final httpPort = resolveHttpPort(args);
  final socketPort = resolveSocketPort(args);

  await Future.wait([
    _startHttpServer(httpPort),
    _startSocketServer(socketPort),
  ]);
}

Future<void> _startHttpServer(int port) async {
  final server = Server();

  server.applyMiddleware(Kernel.middleware);
  server.injectRoutes(registerRoutes);
  server.serveStatic();

  await server.start(port: port);
}

Future<void> _startSocketServer(int port) async {
  final socketServer = SocketServer(
    SocketConfig(port: port),
    manager: Khadem.socket,
  );

  registerSocketRoutes(socketServer);
  await socketServer.start();
}

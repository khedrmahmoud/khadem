import 'dart:async';
import 'dart:io';

import 'package:khadem/khadem.dart'
    show Khadem, ContainerInterface, SocketServer, Server;

import '../core/kernel.dart';
import '../routes/socket.dart';
import '../routes/web.dart';

Future<void> main(List<String> args) async {
  if (_isSnapshotBuild()) return;

  final container = Khadem.container;
  await Kernel.bootstrap();

  final port =
      _extractPort(args) ?? Khadem.env.getInt("APP_PORT", defaultValue: 9000);

  await Future.wait([
    _startHttpServer(port, container),
    _startSocketServer(container, Khadem.socket),
  ]);
}

bool _isSnapshotBuild() =>
    Platform.environment.containsKey('KHADIM_JIT_TRAINING');

Future _startHttpServer(int port, ContainerInterface container) async {
  final server = Server();
  registerRoutes(server);
  server.setInitializer(() async {
    registerRoutes(server);
    await server.start(port: port);
  });
  await server.reload();
}

Future<void> _startSocketServer(container, manager) async {
  final socketPort = Khadem.env.getInt("SOCKET_PORT", defaultValue: 8080);
  final socketServer = SocketServer(socketPort, manager: manager);

  registerSocketRoutes(socketServer); // 👈 Socket routes

  await socketServer.start();
}

int? _extractPort(List<String> args) {
  final portIndex = args.indexOf('--port');
  if (portIndex != -1 && args.length > portIndex + 1) {
    return int.tryParse(args[portIndex + 1]);
  }
  return null;
}

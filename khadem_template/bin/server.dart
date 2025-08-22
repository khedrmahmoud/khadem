import 'dart:async';
import 'dart:io';

import 'package:khadem/khadem_dart.dart'
    show Khadem, ServerCluster, ContainerInterface, Lang, SocketServer, Server;

import '../bootstrap/app.dart';
import '../routes/web.dart';
import '../routes/socket.dart';
 
Future<void> main(List<String> args) async {
  if (_isSnapshotBuild()) return;

  final container = Khadem.container;
  await bootstrap(container);

  final port =
      _extractPort(args) ?? Khadem.env.getInt("APP_PORT", defaultValue: 9000);

  await ServerCluster(
    port: port,
    globalBootstrap: () async => await lazyBootStrap(),
    onInit: (server) async {
      server.serveStatic('public');
      await Khadem.use(container);
      Lang.use(container.resolve());
      Khadem.registerDatabaseServices();
      registerRoutes(server);
    },
  ).start();

  await _startSocketServer(container);
}

bool _isSnapshotBuild() =>
    Platform.environment.containsKey('KHADIM_JIT_TRAINING');

Future<void> _startSocketServer(container) async {
  final socketPort = Khadem.env.getInt("SOCKET_PORT", defaultValue: 3000);
  final server = SocketServer(socketPort);

  final socketServer = SocketServer(socketPort);

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

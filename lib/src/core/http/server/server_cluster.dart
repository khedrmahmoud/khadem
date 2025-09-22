import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../../../application/khadem.dart';
import 'server.dart';

/// High-performance cluster-aware HTTP server
class ServerCluster {
  final int port;
  final int instances;
  final FutureOr<void> Function()? globalBootstrap;
  final void Function(Server server)? onInit;
  final List<SendPort> _isolatePorts = [];

  ServerCluster({
    this.port = 8080,
    this.instances = 0,
    this.globalBootstrap,
    this.onInit,
  });

  Future<void> start() async {
    final count = instances > 0 ? instances : Platform.numberOfProcessors;

    for (int i = 0; i < count; i++) {
      final receivePort = ReceivePort();
      _isolatePorts.add(receivePort.sendPort);

      await Isolate.spawn(
        _startInstance,
        {
          'port': port,
          'onInit': onInit,
          'index': i,
          'sendPort': receivePort.sendPort,
        },
        onExit: receivePort.sendPort,
      );
    }

    if (globalBootstrap != null) {
      await globalBootstrap!.call();
    }
    Khadem.logger.info(
      '🔥 Server cluster started on http://localhost:$port with $count isolates [PID: $pid]',
    );
  }

  Future<void> reload() async {
    for (final sendPort in _isolatePorts) {
      sendPort.send('reload');
    }
  }

  static Future<void> _startInstance(Map<String, dynamic> args) async {
    final int port = args['port'] as int;
    final void Function(Server server)? onInit =
        args['onInit'] as void Function(Server server)?;
    // final SendPort sendPort = args['sendPort'];
    final server = Server();

    // Set up receive port for reload signals
    // final receivePort = ReceivePort();
    // sendPort.send(receivePort.sendPort);

    // receivePort.listen((message) {
    //   if (message == 'reload') {
    //     server.reload();
    //   }
    // });

    onInit?.call(server);
    await server.start(port: port);
  }
}

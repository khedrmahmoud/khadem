import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../../../application/khadem.dart';
import 'server.dart';

/// High-performance cluster-aware HTTP server with supervision and auto-restart.
class ServerCluster {
  final int port;
  final int instances;
  final FutureOr<void> Function()? globalBootstrap;
  final void Function(Server server)? onInit;
  
  // Map of worker index to its command port
  final Map<int, SendPort> _workerPorts = {};

  ServerCluster({
    this.port = 8080,
    this.instances = 0,
    this.globalBootstrap,
    this.onInit,
  });

  Future<void> start() async {
    final count = instances > 0 ? instances : Platform.numberOfProcessors;

    for (int i = 0; i < count; i++) {
      await _spawnWorker(i);
    }

    if (globalBootstrap != null) {
      await globalBootstrap!.call();
    }
    Khadem.logger.info(
      '🔥 Server cluster started on http://localhost:$port with $count isolates [PID: $pid]',
    );
  }

  Future<void> _spawnWorker(int index) async {
    final handshakePort = ReceivePort();
    final exitPort = ReceivePort();
    final errorPort = ReceivePort();

    await Isolate.spawn(
      _startInstance,
      {
        'port': port,
        'onInit': onInit,
        'index': index,
        'handshakePort': handshakePort.sendPort,
      },
      onExit: exitPort.sendPort,
      onError: errorPort.sendPort,
    );

    // Wait for the worker to send its command port
    final workerCommandPort = await handshakePort.first as SendPort;
    _workerPorts[index] = workerCommandPort;
    handshakePort.close();

    // Handle worker exit
    exitPort.listen((message) {
      Khadem.logger.warning('⚠️ Worker $index exited. Restarting...');
      exitPort.close();
      errorPort.close();
      _spawnWorker(index);
    });

    // Handle worker error
    errorPort.listen((message) {
      Khadem.logger.error('❌ Worker $index error: $message');
    });
  }

  Future<void> reload() async {
    Khadem.logger.info('🔄 Reloading all workers...');
    for (final sendPort in _workerPorts.values) {
      sendPort.send('reload');
    }
  }

  static Future<void> _startInstance(Map<String, dynamic> args) async {
    final int port = args['port'] as int;
    final void Function(Server server)? onInit =
        args['onInit'] as void Function(Server server)?;
    final SendPort handshakePort = args['handshakePort'] as SendPort;
    
    final server = Server();

    // Set up receive port for commands (reload, etc.)
    final commandPort = ReceivePort();
    handshakePort.send(commandPort.sendPort);

    commandPort.listen((message) {
      if (message == 'reload') {
        server.reload();
      }
    });

    onInit?.call(server);
    await server.start(port: port);
  }
}

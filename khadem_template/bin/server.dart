import 'dart:async';
import 'dart:io';

import 'package:khadem/khadem_dart.dart' show Khadem, ServerCluster, Lang;
import '../routes/web.dart';
import '../bootstrap/app.dart';

Future<void> main(List<String> args) async {
  if (Platform.environment.containsKey('KHADIM_JIT_TRAINING')) {
    // ⛔️ Do not start server during snapshot build
    return;
  }

  final port = _extractPort(args);

  // 🌱 Initialize global container
  final container = Khadem.container;

  // 🚀 Bootstrap base app setup (light mode)
  await bootstrap(container);

  // 🧠 Start the clustered server
  await ServerCluster(
    port: port ?? Khadem.env.getInt("APP_PORT", defaultValue: 9000),
    globalBootstrap: () async {
      await lazyBootStrap();
    },
    onInit: (server) async {
      server.serveStatic('public');
      await Khadem.use(container); // sync with main isolate container
      Lang.use(container.resolve());
      Khadem.registerDatabaseServices();
      registerRoutes(server);
    },
  ).start();
}

int? _extractPort(List<String> args) {
  final portIndex = args.indexOf('--port');
  if (portIndex != -1 && args.length > portIndex + 1) {
    return int.tryParse(args[portIndex + 1]);
  }
  return null;
}

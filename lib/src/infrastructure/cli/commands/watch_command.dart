import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../bus/command.dart';

class WatchCommand extends KhademCommand {
  @override
  String get name => 'watch';

  @override
  String get description =>
      'Start development server with automatic hot restart or reload on file changes';

  WatchCommand({required super.logger}) {
    argParser.addOption('port',
        abbr: 'p', help: 'Port to run the server on', defaultsTo: '8080');
    argParser.addFlag('reload',
        help: 'Attempt hot reload instead of restart (experimental)',
        defaultsTo: false);
  }

  Process? _serverProcess;
  late final List<StreamSubscription<FileSystemEvent>> _watchers;
  Timer? _debounce;
  bool _restarting = false;
  late String _port;

  final List<String> _watchDirs = [
    'lib',
    'app',
    'routes',
    'bin',
    'bootstrap',
    'config',
    'core',
    'lang',
    'resources',
  ];

  final List<String> _watchExtensions = ['.dart', '.env'];

  @override
  Future<void> handle(List<String> args) async {
    _port = argResults?['port'] as String? ?? '8080';
    final enableHotReload = argResults?['reload'] as bool? ?? false;

    // Register signal handlers for graceful shutdown
    ProcessSignal.sigint.watch().listen((_) => _shutdown());

    if (!Platform.isWindows) {
      try {
        ProcessSignal.sigterm.watch().listen((_) => _shutdown());
      } catch (e) {
        logger.warning('⚠️ SIGTERM signal not supported on this platform: $e');
      }
    } else {
      logger.info('⚠️ SIGTERM handling skipped on Windows');
    }

    // Start the initial server
    await _startServer(_port, enableHotReload);

    // Watch for changes
    _watchFiles(_port, enableHotReload);

    logger.info('🚀 Server running on port $_port. Watching for changes...\n');
  }

  Future<void> _startServer(String port, bool enableHotReload) async {
    try {
      if (_serverProcess != null) {
        logger.info('🔁 Restarting server...');
        _serverProcess!.kill(ProcessSignal.sigterm);
        await _serverProcess!.exitCode.timeout(Duration(seconds: 5),
            onTimeout: () {
          _serverProcess!.kill(ProcessSignal.sigkill);
          logger.warning(
              '⚠️ Forced termination of server process (PID: ${_serverProcess!.pid})');
          return 0;
        });
      }

      // Check port availability
      if (!await _isPortAvailable('localhost', int.parse(port))) {
        logger.error('❌ Port $port is already in use');
        await _shutdown();
        exit(1);
      }

      final args = ['run', 'bin/server.dart', '--port', port];
      if (enableHotReload) {
        args.add('--enable-hot-reload');
      }

      _serverProcess = await Process.start(
        'dart',
        args,
        runInShell: true,
        mode: ProcessStartMode.normal,
      );

      _serverProcess!.stdout.transform(utf8.decoder).listen(
            (data) => stdout.write(data),
            onError: (e) => logger.error('❌ Server stdout error: $e'),
            onDone: () => logger.info('Server stdout closed'),
          );

      _serverProcess!.stderr.transform(utf8.decoder).listen(
            (data) => stderr.write(data),
            onError: (e) => logger.error('❌ Server stderr error: $e'),
            onDone: () => logger.info('Server stderr closed'),
          );

      _serverProcess!.exitCode.then((code) {
        if (code != 0 && !_restarting) {
          logger.error('❌ Server exited with code $code');
        }
      });

      logger.info('✅ Server started (PID: ${_serverProcess!.pid})');
    } catch (e) {
      logger.error('❌ Failed to start server: $e');
      await _shutdown();
      exit(1);
    }
  }

  void _watchFiles(String port, bool enableHotReload) {
    _watchers = [];

    for (final dir in _watchDirs) {
      final directory = Directory(dir);
      if (!directory.existsSync()) {
        logger.warning('⚠️ Directory "$dir" not found. Skipping.');
        continue;
      }

      final watcher = directory.watch(recursive: true).listen((event) {
        final path = event.path;
        if (!_watchExtensions.any((ext) => path.endsWith(ext))) return;

        logger.info('📝 Change detected in: $path');

        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () async {
          if (_restarting) return;
          _restarting = true;

          if (enableHotReload) {
            await _attemptHotReload(path);
          } else {
            await _startServer(port, enableHotReload);
          }

          _restarting = false;
        });
      }, onError: (e) {
        logger.error('❌ Watcher error in $dir: $e');
      });

      _watchers.add(watcher);
    }
  }

  Future<void> _attemptHotReload(String path) async {
    try {
      logger.info('🔄 Attempting hot reload via /reload...');
      final client = HttpClient();
      final request =
          await client.postUrl(Uri.parse('http://localhost:$_port/reload'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        logger.info('✅ Hot reload successful: $body');
      } else {
        logger.warning(
            '⚠️ Hot reload failed (status: ${response.statusCode}), falling back to restart...');
        await _startServer(_port, false);
      }
      client.close();
    } catch (e) {
      logger.error('❌ Hot reload failed: $e');
      await _startServer(_port, false);
    }
  }

  Future<bool> _isPortAvailable(String host, int port) async {
    try {
      final server = await ServerSocket.bind(host, port);
      await server.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _shutdown() async {
    logger.info('🛑 Shutting down...');

    _debounce?.cancel();
    for (final watcher in _watchers) {
      await watcher.cancel();
    }

    if (_serverProcess != null) {
      _serverProcess!.kill(
          Platform.isWindows ? ProcessSignal.sigint : ProcessSignal.sigterm);
      await _serverProcess!.exitCode.timeout(Duration(seconds: 5),
          onTimeout: () {
        _serverProcess!.kill(ProcessSignal.sigkill);
        return 0;
      });
      _serverProcess = null;
    }

    logger.info('👋 Server shutdown complete');
    exit(0);
  }
}

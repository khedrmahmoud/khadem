import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';
import 'package:watcher/watcher.dart';
import '../bus/command.dart';

class ServeCommand extends KhademCommand {
  Process? _serverProcess;
  vm.VmService? _vmService;
  vm.IsolateRef? _mainIsolate;
  StreamSubscription? _watcherSubscription;
  StreamSubscription? _stdinSubscription;
  Timer? _debounceTimer;

  bool _isRestarting = false;
  bool _isShuttingDown = false;
  String? _vmServiceUri;
  static const int _vmServicePort = 8181;

  @override
  String get name => 'serve';
  @override
  String get description =>
      'Run the development server with hot reload and hot restart.';

  ServeCommand({required super.logger}) {
    argParser.addOption(
      'port',
      abbr: 'p',
      help: 'Port to run the server on (optional)',
    );
    argParser.addFlag(
      'watch',
      abbr: 'w',
      help: 'Watch for file changes and auto-reload',
    );
  }

  @override
  Future<void> handle(List<String> args) async {
    logger.info('🚀 Starting Khadem development server...');

    await _startServer();

    // Set up file watcher for auto-reload
    if (argResults?['watch'] as bool? ?? true) {
      _setupFileWatcher();
    }

    // Set up keyboard commands
    _setupStdinListener();

    // Keep the command alive
    await Completer<void>().future;
  }

  Future<void> _startServer() async {
    final port = argResults?['port'] as String?;

    final serverArgs = [
      'run',
      '--enable-vm-service=$_vmServicePort',
      '--disable-service-auth-codes',
      'lib/main.dart',
    ];

    if (port != null && port.isNotEmpty) {
      serverArgs.addAll(['--port', port]);
    }

    try {
      _serverProcess = await Process.start('dart', serverArgs);
      logger.info('✅ Server started (PID: ${_serverProcess!.pid})');

      // Forward stdout and stderr
      _serverProcess!.stdout.transform(utf8.decoder).listen((line) {
        stdout.write(line);
      });

      _serverProcess!.stderr.transform(utf8.decoder).listen((line) {
        stderr.write(line);
      });

      // Handle server exit
      _serverProcess!.exitCode.then(_handleServerExit);

      // Wait a moment for server to initialize
      await Future.delayed(const Duration(milliseconds: 1500));

      // Try to connect to VM service for hot reload
      await _connectToVmService();
    } catch (e) {
      logger.error('❌ Failed to start server: $e');
      _shutdown();
    }
  }

  Future<void> _connectToVmService() async {
    _vmServiceUri = 'ws://localhost:$_vmServicePort/ws';

    try {
      logger.info('🔗 Connecting to VM Service for hot reload...');
      _vmService = await vmServiceConnectUri(_vmServiceUri!);
      final vm = await _vmService!.getVM();
      _mainIsolate = vm.isolates?.first;

      if (_mainIsolate != null) {
        logger.info('✅ Hot reload enabled (VM Service connected)');
      } else {
        logger.warning('⚠️ Hot reload unavailable (no isolates found)');
      }
    } catch (e) {
      logger
          .warning('⚠️ Hot reload unavailable (VM Service connection failed)');
      _vmService = null;
      _mainIsolate = null;
    }
  }

  void _setupFileWatcher() {
    _watcherSubscription?.cancel();
    final watcher = DirectoryWatcher('.');
    _watcherSubscription = watcher.events.listen((event) {
      if (event.path.endsWith('.dart') && !event.path.contains('.dart_tool')) {
        logger.info('🔄 File change detected: ${event.path}');
        _debouncedHotReload();
      }
    });
    logger.info('👀 Watching for file changes...');
  }

  void _debouncedHotReload() {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Start a new timer with 2 seconds delay
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _hotReload();
    });
  }

  void _setupStdinListener() {
    if (_stdinSubscription != null) return;

    logger.info('💡 Commands: [r] reload | [f] full restart | [q] quit');

    // Use line-based input (works everywhere, just press Enter after command)
    stdin.lineMode = true;
    stdin.echoMode = true;

    _stdinSubscription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final input = line.trim().toLowerCase();
      if (input.isEmpty) return;

      switch (input[0]) {
        case 'r':
          _hotReload();
          break;
        case 'f':
          _fullRestart();
          break;
        case 'q':
        case 'quit':
        case 'exit':
          _shutdown();
          break;
        default:
          logger.info(
            'Unknown command. Use: r (reload), f (full restart), q (quit)',
          );
      }
    });
  }

  Future<void> _hotReload() async {
    if (_vmService == null || _mainIsolate == null) {
      logger.warning('⚠️ Hot reload unavailable, performing full restart...');
      await _fullRestart();
      return;
    }

    logger.info('🔄 Hot reloading...');
    try {
      final result = await _vmService!.reloadSources(_mainIsolate!.id!);
      if (result.success == true) {
        logger.info('✅ Hot reload successful');
      } else {
        logger.error('❌ Hot reload failed');
      }
    } catch (e) {
      logger.error('❌ Hot reload error: $e');
    }
  }

  Future<void> _fullRestart() async {
    if (_isRestarting || _isShuttingDown) return;

    _isRestarting = true;
    logger.info('🔄 Restarting server...');

    // Clean up VM service connection
    _vmService?.dispose();
    _vmService = null;
    _mainIsolate = null;

    // Kill and restart server process
    if (_serverProcess != null) {
      _serverProcess!.kill();
      await _serverProcess!.exitCode
          .timeout(const Duration(seconds: 3), onTimeout: () => -1);
    }

    await _startServer();
    _isRestarting = false;
    logger.info('✅ Server restarted');
  }

  void _handleServerExit(int code) {
    if (_isRestarting || _isShuttingDown) return;

    if (code == 0) {
      logger.info('Server exited cleanly');
      _shutdown();
    } else {
      logger.warning('⚠️ Server exited with code $code');
      logger.info('💡 Fix any errors and save a file to trigger auto-reload');
    }
  }

  void _shutdown() {
    if (_isShuttingDown) return;
    _isShuttingDown = true;

    logger.info('👋 Shutting down server...');

    _debounceTimer?.cancel();
    _watcherSubscription?.cancel();
    _stdinSubscription?.cancel();
    _vmService?.dispose();
    _serverProcess?.kill();

    exit(0);
  }
}

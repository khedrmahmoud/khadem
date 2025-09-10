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
  String? _vmServiceUri;
  Completer<void> _vmServiceConnectedCompleter = Completer<void>();

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
      defaultsTo: true,
    );
  }

  @override
  Future<void> handle(List<String> args) async {
    await _startServer();

    // Wait for the VM service to connect before setting up watchers, but don't fail if it doesn't
    try {
      await _vmServiceConnectedCompleter.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      logger.warning('⚠️ VM Service connection timed out, continuing with file watching only');
    }

    if (argResults?['watch'] as bool? ?? true) {
      _setupFileWatcher();
    }

    _setupStdinListener();

    // Keep the command alive.
    await Completer<void>().future;
  }

  Future<void> _startServer() async {
    logger.info('🚀 Starting server...');
    final port = argResults?['port'] as String?;
    
    // Use a fixed port for VM service to avoid parsing issues
    const vmServicePort = 8181;
    
    final serverArgs = [
      'run',
      '--pause-isolates-on-start',
      '--enable-vm-service=$vmServicePort',
      '--disable-service-auth-codes',
      'bin/server.dart',
    ];

    if (port != null && port.isNotEmpty) {
      serverArgs.addAll(['--port', port]);
    }

    try {
      _serverProcess = await Process.start(
        'dart',
        serverArgs,
      );
      
      logger.info('✅ Server process started with PID: ${_serverProcess!.pid}');
    } catch (e) {
      logger.error('❌ Failed to start server process: $e');
      _shutdown();
      return;
    }

    _serverProcess!.exitCode.then((code) {
      if (code != 0 && code != -15) { // SIGTERM is expected on restart
        logger.error('❌ Server process exited unexpectedly with code $code.');
        _shutdown();
      }
    });

    // Forward stdout and stderr with better error handling
    _serverProcess!.stdout.transform(utf8.decoder).listen(
      (line) {
        stdout.write(line);
        // Look for VM service URI in output
        final match = RegExp(r'The Dart VM service is listening on (ws://[^\s]+)').firstMatch(line);
        if (match != null) {
          _vmServiceUri = match.group(1);
          logger.info('🔗 VM Service URI detected: $_vmServiceUri');
        }
      },
      onError: (error) {
        logger.error('❌ Error reading server stdout: $error');
      },
    );

    _serverProcess!.stderr.transform(utf8.decoder).listen(
      (line) {
        stderr.write(line);
      },
      onError: (error) {
        logger.error('❌ Error reading server stderr: $error');
      },
    );

    // Wait a moment for the server to start
    await Future.delayed(const Duration(seconds: 2));

    // Try to connect to VM service
    _vmServiceUri = 'ws://localhost:$vmServicePort/ws';
    logger.info('🔗 Attempting to connect to VM Service at $_vmServiceUri');
    
    try {
      await _connectToVmService();
    } catch (e) {
      logger.warning('⚠️ VM Service connection failed, falling back to file watching only: $e');
      // Complete the completer even on failure so the command can continue
      if (!_vmServiceConnectedCompleter.isCompleted) {
        _vmServiceConnectedCompleter.complete();
      }
    }
  }

  Future<void> _connectToVmService() async {
    if (_vmServiceUri == null) {
      logger.error('❌ VM Service URI not found. Cannot enable hot reload.');
      _vmServiceConnectedCompleter.completeError('VM Service URI not found');
      return;
    }
    
    // Try multiple times to connect
    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        logger.info('🔗 Connection attempt $attempt/5...');
        _vmService = await vmServiceConnectUri(_vmServiceUri!);
        final vm = await _vmService!.getVM();
        _mainIsolate = vm.isolates?.first;
        
        if (_mainIsolate != null) {
          // Resume the isolate if it's paused (due to --pause-isolates-on-start)
          await _vmService!.resume(_mainIsolate!.id!);
          logger.info('✅ Connected to VM Service. Hot reload and restart are active.');
          _vmServiceConnectedCompleter.complete();
          return;
        } else {
          logger.warning('⚠️ No isolates found in VM, retrying...');
        }
      } catch (e) {
        logger.warning('⚠️ VM Service connection attempt $attempt failed: $e');
        if (attempt < 5) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    
    logger.error('❌ Failed to connect to VM Service after 5 attempts.');
    _vmServiceConnectedCompleter.completeError('Connection failed after retries');
  }

  void _setupFileWatcher() {
    _watcherSubscription?.cancel();
    final watcher = DirectoryWatcher('.');
    _watcherSubscription = watcher.events.listen((event) {
      if (event.path.endsWith('.dart') && !event.path.contains('.dart_tool')) {
        logger.info('🔄 File change detected: ${event.path}');
        _hotReload();
      }
    });
    logger.info('👀 Watching for file changes...');
  }

  void _setupStdinListener() {
    if (_stdinSubscription != null) return;
    logger.info('💡 Press "r" for hot reload, "R" for hot restart, "q" to quit.');
    try {
      stdin.lineMode = false;
      stdin.echoMode = false;
    } catch (e) {
      logger.warning(
          'Could not set terminal to raw mode. Press Enter after typing a command.',);
    }

    _stdinSubscription = stdin.listen((data) {
      final char = String.fromCharCode(data.first).toLowerCase();
      switch (char) {
        case 'r':
          _hotReload();
          break;
        case 'f':
          _hotRestart();
          break;
        case 'q':
          _shutdown();
          break;
      }
    });
  }

  Future<void> _hotReload() async {
    if (_vmService == null || _mainIsolate == null) {
      logger.warning('⚠️ VM Service not available, performing full restart instead');
      await _fullRestart();
      return;
    }
    logger.info('🔄 Performing hot reload...');
    try {
      final result = await _vmService!.reloadSources(_mainIsolate!.id!);
      if (result.success == true) {
        logger.info('✅ Hot reload successful.');
      } else {
        logger.error('❌ Hot reload failed: ${result.json}');
        await _fullRestart();
      }
    } catch (e) {
      logger.error('❌ Hot reload failed: $e');
      await _fullRestart();
    }
  }

  Future<void> _hotRestart() async {
    if (_vmService == null || _mainIsolate == null) {
      logger.warning('⚠️ VM Service not available, performing full restart instead');
      await _fullRestart();
      return;
    }
    logger.info('🔄 Performing hot restart...');
    try {
      // Resume the isolate first if it's paused
      await _vmService!.resume(_mainIsolate!.id!);
      
      // Then call the hot restart service extension
      await _vmService!.callServiceExtension(
        'ext.dart.io.restart',
        isolateId: _mainIsolate!.id!,
      );
      logger.info('✅ Hot restart successful.');
    } catch (e) {
      logger.error('❌ Hot restart failed: $e. Falling back to full restart.');
      await _fullRestart();
    }
  }

  Future<void> _fullRestart() async {
    logger.info('🔄 Performing full restart...');
    
    // Clean up existing connections
    _vmService?.dispose();
    _vmService = null;
    _mainIsolate = null;
    
    if (_serverProcess != null) {
      _serverProcess!.kill();
      await _serverProcess!.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => -1);
    }
    
    // Reset the completer for the new connection
    _vmServiceConnectedCompleter = Completer<void>();
    
    await _startServer();
    
    // Try to wait for VM service connection, but don't block indefinitely
    try {
      await _vmServiceConnectedCompleter.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      logger.warning('⚠️ VM Service reconnection timed out, continuing with file watching only');
    }
  }

  void _shutdown() {
    logger.info('👋 Shutting down...');
    _watcherSubscription?.cancel();
    _stdinSubscription?.cancel();
    _serverProcess?.kill();
    try {
      stdin.lineMode = true;
      stdin.echoMode = true;
    } catch (_) {}
    exit(0);
  }
}

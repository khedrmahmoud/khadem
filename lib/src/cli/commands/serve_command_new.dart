import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';
import 'package:watcher/watcher.dart';
import '../bus/command.dart';

class ServeCommand extends KhademCommand {
  @override
  String get name => 'serve';
  
  @override
  String get description =>
      'Run the development server with hot reload support';

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
    final port = argResults?['port'] as String?;
    final watchFiles = argResults?['watch'] as bool? ?? true;

    final serverPort = port != null ? int.tryParse(port) : 8080;
    logger.info('🚀 Starting server on port $serverPort...');
    logger.info('💡 Press "r" to hot reload, "R" to hot restart, "q" to quit\n');

    await _runServer(port, watchFiles, serverPort ?? 8080);
  }

  Future<void> _runServer(String? port, bool watchFiles, int serverPort) async {
    final serverArgs = ['run', '--observe=0', 'bin/server.dart'];
    if (port != null && port.isNotEmpty) {
      serverArgs.addAll(['--define=PORT=$port']);
    }

    // Start the process and capture stdout to get VM service URI
    final process = await Process.start(
      'dart',
      serverArgs,
    );

    // Forward process output and capture VM service URI
    String? vmServiceUri;
    final stdoutCompleter = Completer<void>();
    final stderrCompleter = Completer<void>();

    process.stdout.transform(utf8.decoder).listen((data) {
      stdout.write(data);
      
      // Look for VM service URI in the output
      final vmServiceMatch = RegExp(r'The Dart VM service is listening on (http://[^\s]+)').firstMatch(data);
      if (vmServiceMatch != null) {
        vmServiceUri = vmServiceMatch.group(1);
        logger.info('🔗 VM Service URI detected: $vmServiceUri');
      }
    }, onDone: stdoutCompleter.complete);

    process.stderr.transform(utf8.decoder).listen((data) {
      stderr.write(data);
    }, onDone: stderrCompleter.complete);

    // Wait a bit for the server to start and VM service URI to be available
    await Future.delayed(const Duration(seconds: 2));

    // Connect to VM service
    vm.VmService? vmService;
    vm.IsolateRef? isolate;

    if (vmServiceUri != null) {
      try {
        vmService = await vmServiceConnectUri(vmServiceUri!);
        final vmObj = await vmService.getVM();
        isolate = vmObj.isolates?.first;
        logger.info('✅ Connected to VM service for hot reload');
      } catch (e) {
        logger.error('❌ Failed to connect to VM service: $e');
      }
    }

    if (vmService == null || isolate == null) {
      logger.info('💡 Running without hot reload. File changes will require manual restart.');
    }

    // Function to trigger hot reload
    Future<void> hotReload() async {
      if (vmService == null || isolate == null) {
        logger.error('❌ VM service not available for hot reload');
        return;
      }
      try {
        final result = await vmService!.reloadSources(isolate!.id!);
        if (result.success == true) {
          logger.info('🔄 Hot reload successful!');
        } else {
          logger.error('❌ Hot reload failed: ${result.json}');
        }
      } catch (e) {
        logger.error('❌ Hot reload failed: $e');
      }
    }

    // Function to trigger hot restart
    Future<void> hotRestart() async {
      if (vmService == null || isolate == null) {
        logger.error('❌ VM service not available for hot restart');
        await _fullRestart(process, port, watchFiles, serverPort);
        return;
      }
      try {
        // Kill the main isolate to trigger restart
        await vmService!.kill(isolate!.id!); 
        logger.info('🔄 Hot restart successful!');
        
        // Wait a bit and reconnect to the new isolate
        await Future.delayed(const Duration(milliseconds: 500));
        final vmObj = await vmService!.getVM();
        isolate = vmObj.isolates?.first;
      } catch (e) {
        logger.error('❌ Hot restart failed: $e');
        logger.info('💡 Falling back to full restart...');
        await _fullRestart(process, port, watchFiles, serverPort);
      }
    }

    // File watcher for auto-reload
    StreamSubscription? watcherSubscription;
    if (watchFiles) {
      final watcher = DirectoryWatcher('.');
      watcherSubscription = watcher.events.listen((event) {
        if (event.path.endsWith('.dart')) {
          logger.info('🔄 Detected change in ${event.path}, triggering hot reload...');
          hotReload();
        }
      });
    }

    // Listen for keyboard input (Windows-compatible)
    StreamSubscription? inputSubscription;
    try {
      if (Platform.isWindows) {
        // Windows-specific input handling - use line mode
        stdin.lineMode = true;
        inputSubscription = stdin.transform(utf8.decoder).listen((line) async {
          final input = line.trim();
          await _handleInput(input, hotReload, hotRestart, process, watcherSubscription);
        });
        logger.info('💡 Type "r" + Enter for hot reload, "R" + Enter for hot restart, "q" + Enter to quit');
      } else {
        // Unix-like systems - character by character
        stdin.echoMode = false;
        stdin.lineMode = false;
        inputSubscription = stdin.listen((data) async {
          final char = String.fromCharCode(data[0]);
          await _handleInput(char, hotReload, hotRestart, process, watcherSubscription);
        });
      }
    } catch (e) {
      logger.error('❌ Failed to setup input listener: $e');
      logger.info('💡 Hot reload will work through file watching only');
    }

    // Wait for the process to exit
    final exitCode = await process.exitCode;

    // Clean up
    await inputSubscription?.cancel();
    await watcherSubscription?.cancel();
    
    if (!Platform.isWindows) {
      try {
        stdin.echoMode = true;
        stdin.lineMode = true;
      } catch (e) {
        // Ignore cleanup errors
      }
    }

    if (exitCode != 0) {
      logger.error('❌ Server exited with code $exitCode');
      exit(exitCode);
    }
  }

  Future<void> _handleInput(
    String input, 
    Future<void> Function() hotReload,
    Future<void> Function() hotRestart,
    Process process,
    StreamSubscription? watcherSubscription,
  ) async {
    switch (input.toLowerCase()) {
      case 'r':
        logger.info('🔄 Triggering hot reload...');
        await hotReload();
        break;
      case 'R':
        logger.info('🔄 Triggering hot restart...');
        await hotRestart();
        break;
      case 'q':
        logger.info('👋 Shutting down server...');
        process.kill();
        await watcherSubscription?.cancel();
        exit(0);
    }
  }

  Future<void> _fullRestart(Process currentProcess, String? port, bool watchFiles, int serverPort) async {
    logger.info('🔄 Performing full restart...');
    
    // Kill current process
    currentProcess.kill();
    
    // Wait a bit for cleanup
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Start new server process
    await _runServer(port, watchFiles, serverPort);
  }
}


// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:vm_service/vm_service.dart' as vm;
// import 'package:vm_service/vm_service_io.dart';
// import 'package:watcher/watcher.dart';
// import '../bus/command.dart';

// class ServeCommand extends KhademCommand {
//   @override
//   String get name => 'serve';
//   @override
//   String get description =>
//       'Run the development server with hot reload support';

//   ServeCommand({required super.logger}) {
//     argParser.addOption(
//       'port',
//       abbr: 'p',
//       help: 'Port to run the server on (optional)',
//     );
//     argParser.addFlag(
//       'watch',
//       abbr: 'w',
//       help: 'Watch for file changes and auto-reload',
//       defaultsTo: true,
//     );
//   }

//   @override
//   Future<void> handle(List<String> args) async {
//     final port = argResults?['port'] as String?;
//     final watchFiles = argResults?['watch'] as bool? ?? true;

//     final serverArgs = ['run', '--enable-vm-service=0', 'bin/server.dart'];
//     if (port != null && port.isNotEmpty) {
//       serverArgs.addAll(['--define=PORT=$port']);
//     }

//     final serverPort = port != null ? int.tryParse(port) : 8080;
//     logger.info('🚀 Starting server on port $serverPort...');
//     logger.info('💡 Press "r" to hot reload, "R" to hot restart, "q" to quit\n');

//     // Start process with stdout/stderr capture to get VM service URI
//     final process = await Process.start(
//       'dart',
//       serverArgs,
//       mode: ProcessStartMode.normal,
//     );

//     // Forward process output and capture VM service URI
//     String? vmServiceUri;
//     process.stdout.transform(utf8.decoder).listen((data) {
//       stdout.write(data);
//       // Look for VM service URI in the output
//       final vmServiceMatch = RegExp(r'The Dart VM service is listening on (http://[^\s]+)').firstMatch(data);
//       if (vmServiceMatch != null) {
//         vmServiceUri = vmServiceMatch.group(1);
//         logger.info('🔗 VM Service URI detected: $vmServiceUri');
//       }
//     });

//     process.stderr.transform(utf8.decoder).listen((data) {
//       stderr.write(data);
//     });

//     // Wait for VM service to be available
//     await Future.delayed(const Duration(seconds: 2));

//     // Connect to VM service
//     vm.VmService? vmService;
//     vm.IsolateRef? isolate;

//     // Wait for VM service to be available
//     for (int i = 0; i < 10; i++) {
//       try {
//         if (vmServiceUri != null) {
//           vmService = await vmServiceConnectUri(vmServiceUri!);
//           final vmObj = await vmService.getVM();
//           isolate = vmObj.isolates?.first;
//           logger.info('✅ Connected to VM service for hot reload');
//           break;
//         }
//       } catch (e) {
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     if (vmService == null || isolate == null) {
//       logger.info('💡 Running without hot reload. File changes will require manual restart.');
//     }

//     // Function to trigger hot reload
//     Future<void> hotReload() async {
//       if (vmService == null || isolate == null) {
//         logger.error('❌ VM service not available for hot reload');
//         return;
//       }
//       try {
//         final result = await vmService!.reloadSources(isolate!.id!);
//         if (result.success == true) {
//           logger.info('🔄 Hot reload successful!');
//         } else {
//           logger.error('❌ Hot reload failed');
//         }
//       } catch (e) {
//         logger.error('❌ Hot reload failed: $e');
//       }
//     }

//     // Full restart of the server process
//     Future<void> fullRestart() async {
//       logger.info('🔄 Performing full restart...');
//       process.kill();
//       // Start a new process
//       await Process.start(
//         'dart',
//         serverArgs,
//         mode: ProcessStartMode.inheritStdio,
//       );

//       // Reconnect to VM service for the new process
//       vmService = null;
//       isolate = null;
//       for (int i = 0; i < 10; i++) {
//         try {
//           if (vmServiceUri != null) {
//             vmService = await vmServiceConnectUri(vmServiceUri!);
//             final vmObj = await vmService!.getVM();
//             isolate = vmObj.isolates?.first;
//             break;
//           }
//         } catch (e) {
//           await Future.delayed(const Duration(seconds: 1));
//         }
//       }
//       if (vmService == null || isolate == null) {
//         logger.error('❌ Failed to reconnect to VM service after restart');
//       } else {
//         logger.info('🔄 VM service reconnected');
//       }
//       // Update the process reference (in a real implementation, you'd need to handle this more carefully)
//       // For now, we'll just log and then exit the current process because we can't easily replace the process reference in this context
//       logger.info('🔄 Server fully restarted');
//       // We cannot easily replace the process variable in this context, so we'll exit the current process and let the new one take over
//       // However, note that this will terminate the current process and the watcher and input listeners
//       // So we'll exit the current process
//       // exit(0);
//     }

//     // Function to trigger hot restart
//     Future<void> hotRestart() async {
//       if (vmService == null || isolate == null) {
//         logger.error('❌ VM service not available for hot restart');
//         logger.info('💡 Falling back to full restart...');
//         await fullRestart();
//         return;
//       }
//       try {
//         // Kill the isolate to trigger restart (like server_lifecycle.dart)
//         await vmService!.kill(isolate!.id!);
//         logger.info('🔄 Hot restart successful!');
        
//         // Wait and reconnect to new isolate
//         await Future.delayed(const Duration(milliseconds: 500));
//         final vmObj = await vmService!.getVM();
//         isolate = vmObj.isolates?.first;
//       } catch (e) {
//         logger.error('❌ Hot restart failed: $e');
//         logger.info('💡 Falling back to full restart...');
//         await fullRestart();
//       }
//     }

//     // File watcher for auto-reload
//     StreamSubscription? watcherSubscription;
//     if (watchFiles) {
//       final watcher = DirectoryWatcher('.');
//       watcherSubscription = watcher.events.listen((event) {
//         if (event.path.endsWith('.dart')) {
//           logger.info(
//               '🔄 Detected change in ${event.path}, triggering hot reload...',);
//           hotReload();
//         }
//       });
//     }

//     // Listen for keyboard input (Windows-compatible)
//     StreamSubscription? inputSubscription;
//     try {
//       if (Platform.isWindows) {
//         // Windows-specific input handling - use line mode
//         stdin.lineMode = true;
//         inputSubscription = stdin.transform(utf8.decoder).listen((line) async {
//           final input = line.trim();
//           switch (input.toLowerCase()) {
//             case 'r':
//               logger.info('🔄 Triggering hot reload...');
//               await hotReload();
//               break;
//             case 'R':
//               logger.info('🔄 Triggering hot restart...');
//               await hotRestart();
//               break;
//             case 'q':
//               logger.info('👋 Shutting down server...');
//               process.kill();
//               await watcherSubscription?.cancel();
//               exit(0);
//           }
//         });
//         logger.info('💡 Type "r" + Enter for hot reload, "R" + Enter for hot restart, "q" + Enter to quit');
//       } else {
//         // Unix-like systems - character by character
//         stdin.echoMode = false;
//         stdin.lineMode = false;
//         inputSubscription = stdin.listen((data) async {
//           final char = String.fromCharCode(data[0]);
//           switch (char) {
//             case 'r':
//               logger.info('🔄 Triggering hot reload...');
//               await hotReload();
//               break;
//             case 'R':
//               logger.info('🔄 Triggering hot restart...');
//               await hotRestart();
//               break;
//             case 'q':
//             case 'Q':
//               logger.info('👋 Shutting down server...');
//               process.kill();
//               await watcherSubscription?.cancel();
//               exit(0);
//           }
//         });
//       }
//     } catch (e) {
//       logger.error('❌ Failed to setup input listener: $e');
//       logger.info('💡 Hot reload will work through file watching only');
//     }

//     // Wait for the process to exit
//     final exitCode = await process.exitCode;

//     // Clean up
//     await inputSubscription?.cancel();
//     await watcherSubscription?.cancel();
    
//     if (!Platform.isWindows) {
//       try {
//         stdin.echoMode = true;
//         stdin.lineMode = true;
//       } catch (e) {
//         // Ignore cleanup errors on non-Windows platforms
//       }
//     }

//     if (exitCode != 0) {
//       logger.error('❌ Server exited with code $exitCode');
//       exit(exitCode);
//     }
//   }
// }

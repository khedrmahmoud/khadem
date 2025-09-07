import 'dart:async';
import 'dart:io';

import '../bus/command.dart';

class ServeCommand extends KhademCommand {
  @override
  String get name => 'serve';
  @override
  String get description => 'Run the development server with hot reload support';

  ServeCommand({required super.logger}) {
    argParser.addOption('port',
        abbr: 'p', help: 'Port to run the server on (optional)',);
  }

  @override
  Future<void> handle(List<String> args) async {
    final port = argResults?['port'] as String?;
    final serverArgs = ['run', 'bin/server.dart'];

    if (port != null && port.isNotEmpty) {
      serverArgs.addAll(['--port', port]);
    }

    final serverPort = port != null ? int.tryParse(port) : 8080;
    logger.info('🚀 Starting server on port $serverPort...');
    logger.info('💡 Press "r" to hot reload, "q" to quit\n');

    final process = await Process.start(
      'dart',
      serverArgs,
      mode: ProcessStartMode.inheritStdio,
    );

    // Function to trigger hot reload
    Future<void> hotReload() async {
      try {
        final client = HttpClient();
        final request = await client.post('localhost', serverPort!, '/reload');
        request.headers.contentType = ContentType.json;

        final response = await request.close();

        if (response.statusCode == 200) {
          logger.info('🔄 Hot reload successful!');
        } else {
          logger.error('❌ Hot reload failed: ${response.statusCode}');
        }

        client.close();
      } catch (e) {
        logger.error('❌ Failed to connect to server for reload: $e');
        logger.info('💡 Make sure the server is running and accessible');
      }
    }

    // Listen for keyboard input
    stdin.echoMode = false;
    stdin.lineMode = false;

    final inputSubscription = stdin.listen((data) {
      final char = String.fromCharCode(data[0]);

      switch (char) {
        case 'r':
        case 'R':
          logger.info('🔄 Triggering hot reload...');
          hotReload();
          break;
        case 'q':
        case 'Q':
          logger.info('👋 Shutting down server...');
          process.kill();
          exit(0);
      }
    });

    // Wait for the process to exit
    final exitCode = await process.exitCode;

    // Clean up
    await inputSubscription.cancel();
    stdin.echoMode = true;
    stdin.lineMode = true;

    if (exitCode != 0) {
      logger.error('❌ Server exited with code $exitCode');
      exit(exitCode);
    }
  }
}

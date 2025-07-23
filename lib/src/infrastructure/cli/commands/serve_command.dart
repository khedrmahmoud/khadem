import 'dart:io';

import '../bus/command.dart';

class ServeCommand extends KhademCommand {
  @override
  String get name => 'serve';
  @override
  String get description => 'Run the development server';

  ServeCommand({required super.logger}) {
    argParser.addOption('port',
        abbr: 'p', help: 'Port to run the server on (optional)');
  }

  @override
  Future<void> handle(List<String> args) async {
    final port = argResults?['port'] as String?;
    final args = ['run', 'bin/server.dart'];

    if (port != null && port.isNotEmpty) {
      args.addAll(['--port', port]);
    }

    logger
        .info('🚀 Starting server${port != null ? ' on port $port' : ''}...\n');

    final process = await Process.start(
      'dart',
      args,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      logger.error('❌ Server exited with code $exitCode');
      exit(exitCode);
    }
  }
}

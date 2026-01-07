import 'dart:io';

import '../bus/command.dart';

class DoctorCommand extends KhademCommand {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Diagnose your Khadem project and environment.';

  DoctorCommand({required super.logger});

  @override
  Future<void> handle(List<String> args) async {
    var ok = true;

    logger.info('🩺 Khadem Doctor');
    logger.info('');

    logger.info('Environment:');
    logger.info('- OS: ${Platform.operatingSystem}');
    logger.info('- Dart: ${Platform.version.split(' ').first}');
    logger.info('- Executable: ${Platform.resolvedExecutable}');

    logger.info('');
    logger.info('Project:');

    final cwd = Directory.current.path;
    logger.info('- Working directory: $cwd');

    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      ok = false;
      logger.error('- pubspec.yaml: missing');
    } else {
      logger.info('- pubspec.yaml: found');
    }

    final main = File('lib/main.dart');
    final exampleMain = File('example/lib/main.dart');
    final packageEntrypoint = File('lib/khadem.dart');
    if (main.existsSync()) {
      logger.info('- lib/main.dart: found');
    } else if (exampleMain.existsSync()) {
      logger.info('- lib/main.dart: missing (example app found)');
      logger.info('- example/lib/main.dart: found');
    } else if (packageEntrypoint.existsSync()) {
      logger.info('- lib/main.dart: missing (package entrypoint found)');
      logger.info('- lib/khadem.dart: found');
    } else {
      ok = false;
      logger.error('- lib/main.dart: missing');
      logger.error('- example/lib/main.dart: missing');
      logger.error('- lib/khadem.dart: missing');
    }

    final appDir = Directory('lib/app');
    if (!appDir.existsSync()) {
      logger.warning('- lib/app: missing (ok for packages)');
    } else {
      logger.info('- lib/app: found');
    }

    final storageDir = Directory('storage');
    if (!storageDir.existsSync()) {
      logger.warning('- storage/: missing');
    } else {
      logger.info('- storage/: found');
    }

    logger.info('');
    if (ok) {
      logger.info('✅ Doctor: OK');
      exitCode = 0;
      return;
    }

    logger.error('❌ Doctor: issues found');
    exitCode = 1;
  }
}

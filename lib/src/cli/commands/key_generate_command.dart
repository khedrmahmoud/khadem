import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../bus/command.dart';

class KeyGenerateCommand extends KhademCommand {
  KeyGenerateCommand({required super.logger});

  @override
  String get name => 'key:generate';

  @override
  String get description => 'Set the application key';

  @override
  Future<void> handle(List<String> args) async {
    final envFile = File('.env');

    if (!await envFile.exists()) {
      final exampleFile = File('.env.example');

      if (await exampleFile.exists()) {
        await exampleFile.copy('.env');
        logger.info(' Created .env from .env.example');
      } else {
        await envFile.writeAsString('');
        logger.info(' Created .env');
      }
    }

    final key = _generateRandomKey();

    final keyPattern = RegExp(r'^APP_KEY=.*$', multiLine: true);
    var content = await envFile.readAsString();

    if (keyPattern.hasMatch(content)) {
      content = content.replaceAll(keyPattern, 'APP_KEY=$key');
    } else {
      if (content.isNotEmpty && !content.endsWith('\n')) {
        content += '\n';
      }
      content += 'APP_KEY=$key\n';
    }

    await envFile.writeAsString(content);
    logger.info(' Application key set successfully: $key');
    exitCode = 0;
  }

  String _generateRandomKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }
}

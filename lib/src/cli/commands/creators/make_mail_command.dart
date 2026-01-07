import 'dart:io';

import '../../bus/command.dart';
import '../../utils/cli_naming.dart';

class MakeMailCommand extends KhademCommand {
  MakeMailCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Mailable name (e.g. WelcomeEmail)',
    );
  }

  @override
  String get name => 'make:mail';

  @override
  String get description => 'Create a new email class';

  @override
  Future<void> handle(List<String> args) async {
    final input = argResults?['name'] as String?;
    if (input == null || input.trim().isEmpty) {
      logger.error('❌ Usage: khadem make:mail --name=WelcomeEmail');
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(input);
    final folder = parts.folder;
    final rawName = parts.name;
    final className = CliNaming.toPascalCase(rawName);
    final fileName = '${CliNaming.toSnakeCase(rawName)}.dart';

    final relativePath = folder.isEmpty
        ? 'lib/app/mail/$fileName'
        : 'lib/app/mail/$folder/$fileName';

    final file = File(relativePath);
    if (await file.exists()) {
      logger.error('❌ Mailable "$fileName" already exists at "$relativePath"');
      exitCode = 1;
      return;
    }

    await file.create(recursive: true);
    await file.writeAsString(_stub(className));

    logger.info('✅ Mailable "$className" created at "$relativePath"');
    exitCode = 0;
  }

  String _stub(String className) {
    return '''
import 'package:khadem/khadem.dart';

class $className extends Mailable {
  final String name;

  $className(this.name);

  @override
  Future<void> build(MailerInterface mailer) async {
    await mailer
        .subject('Welcome to Khadem')
        .view('emails.welcome', {'name': name});
  }
}
''';
  }
}

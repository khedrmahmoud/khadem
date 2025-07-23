import 'dart:io';

import '../../bus/command.dart';

class MakeListenerCommand extends KhademCommand {
  MakeListenerCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Listener name (e.g., Post)');
  }

  @override
  String get name => 'make:listener';

  @override
  String get description => 'Create a new event listener / handler class';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.isEmpty) {
      logger.error('❌ Usage: dart run khadem make:listener --name=Post');
      exit(1);
    }

    final className = '${_capitalize(name)}EventsHandler';
    final fileName = '${_snakeCase(name)}_events_handler.dart';
    final filePath = 'app/listeners/$fileName';

    final file = File(filePath);
    await file.create(recursive: true);

    await file.writeAsString('''
import 'package:khadem/khadem_dart.dart'
    show Khadem, EventMethod, EventSubscriberInterface;

class $className implements EventSubscriberInterface {
  @override
  List<EventMethod> getEventHandlers() => [
        EventMethod(
          eventName: '${_snakeCase(name)}.created',
          handler: (payload) async => await onCreated(payload),
        ),
        EventMethod(
          eventName: '${_snakeCase(name)}.updated',
          handler: (payload) async => await onUpdated(payload),
        ),
        EventMethod(
          eventName: '${_snakeCase(name)}.deleted',
          handler: (payload) async => await onDeleted(payload),
        ),
      ];

  Future onCreated(dynamic payload) async {
    print('📥 ${_capitalize(name)} created: \$payload');
  }

  Future onUpdated(dynamic payload) async {
    print('✏️ ${_capitalize(name)} updated: \$payload');
  }

  Future onDeleted(dynamic payload) async {
    print('🗑️ ${_capitalize(name)} deleted: \$payload');
  }
}
''');

    logger.info('✅ Listener "$className" created at $filePath');
    exit(0);
  }

  String _capitalize(String input) =>
      input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);

  String _snakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}

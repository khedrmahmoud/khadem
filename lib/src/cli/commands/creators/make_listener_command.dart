import 'dart:io';

import '../../bus/command.dart';

class MakeListenerCommand extends KhademCommand {
  MakeListenerCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Listener name (e.g., Post or auth/UserEventsHandler)');
  }

  @override
  String get name => 'make:listener';

  @override
  String get description => 'Create a new event listener / handler class with optional folder structure';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.isEmpty) {
      logger.error('❌ Usage: khadem make:listener --name=ListenerName or --name=folder/ListenerName');
      exit(1);
    }

    // Parse folder and listener name
    final parts = name.split('/');
    String folder = '';
    String listenerName = parts.last;

    if (parts.length > 1) {
      folder = parts.sublist(0, parts.length - 1).join('/');
    }

    // Ensure listener name ends with 'EventsHandler'
    if (!listenerName.endsWith('EventsHandler')) {
      listenerName = '${listenerName}EventsHandler';
    }

    final className = _capitalize(listenerName);
    final fileName = '${_snakeCase(listenerName.replaceAll('EventsHandler', ''))}_events_handler.dart';
    final relativePath = folder.isEmpty
        ? 'app/listeners/$fileName'
        : 'app/listeners/$folder/$fileName';

    final file = File(relativePath);
    await file.create(recursive: true);

    await file.writeAsString(_listenerStub(className, listenerName.replaceAll('EventsHandler', ''), folder));

    logger.info('✅ Listener "$className" created at "$relativePath"');
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

  String _listenerStub(String className, String listenerName, String folder) {
    final namespace = folder.isEmpty ? '' : '$folder/';
    return '''
import 'package:khadem/khadem.dart'
    show Khadem, EventMethod, EventSubscriberInterface;

class $className implements EventSubscriberInterface {
  @override
  List<EventMethod> getEventHandlers() => [
        EventMethod(
          eventName: '${_snakeCase(listenerName)}.created',
          handler: (payload) async => await onCreated(payload),
        ),
        EventMethod(
          eventName: '${_snakeCase(listenerName)}.updated',
          handler: (payload) async => await onUpdated(payload),
        ),
        EventMethod(
          eventName: '${_snakeCase(listenerName)}.deleted',
          handler: (payload) async => await onDeleted(payload),
        ),
      ];

  Future onCreated(dynamic payload) async {
    print('📥 ${namespace}${_capitalize(listenerName)} created: \$payload');
  }

  Future onUpdated(dynamic payload) async {
    print('✏️ ${namespace}${_capitalize(listenerName)} updated: \$payload');
  }

  Future onDeleted(dynamic payload) async {
    print('🗑️ ${namespace}${_capitalize(listenerName)} deleted: \$payload');
  }
}
''';
  }
}

import 'dart:io';

import '../../bus/command.dart';
import '../../utils/cli_naming.dart';

class MakeListenerCommand extends KhademCommand {
  MakeListenerCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Listener name (e.g., Post or auth/UserEventsHandler)',
    );
  }

  @override
  String get name => 'make:listener';

  @override
  String get description =>
      'Create a new event listener / handler class with optional folder structure';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.isEmpty) {
      logger.error(
        '❌ Usage: khadem make:listener --name=ListenerName or --name=folder/ListenerName',
      );
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(name);
    final folder = parts.folder;
    var listenerName = parts.name;

    // Ensure listener name ends with 'EventsHandler'
    listenerName = CliNaming.ensureSuffix(
      CliNaming.toPascalCase(listenerName),
      'EventsHandler',
    );

    final className = listenerName;
    final listenerBase = listenerName.replaceAll('EventsHandler', '');
    final fileName =
        '${CliNaming.toSnakeCase(listenerBase)}_events_handler.dart';
    final relativePath = folder.isEmpty
        ? 'lib/app/listeners/$fileName'
        : 'lib/app/listeners/$folder/$fileName';

    final file = File(relativePath);
    await file.create(recursive: true);

    await file.writeAsString(
      _listenerStub(
        className,
        listenerBase,
        folder,
      ),
    );

    logger.info('✅ Listener "$className" created at "$relativePath"');
    exitCode = 0;
    return;
  }

  String _listenerStub(String className, String listenerName, String folder) {
    final namespace = folder.isEmpty ? '' : '$folder/';
    final eventBase = CliNaming.toSnakeCase(listenerName);
    final displayName = CliNaming.toPascalCase(listenerName);
    return '''
import 'package:khadem/khadem.dart'
    show Khadem, EventMethod, EventSubscriberInterface;

class $className implements EventSubscriberInterface {
  @override
  List<EventMethod> getEventHandlers() => [
        EventMethod(
          eventName: '$eventBase.created',
          handler: (payload) async => await onCreated(payload),
        ),
        EventMethod(
          eventName: '$eventBase.updated',
          handler: (payload) async => await onUpdated(payload),
        ),
        EventMethod(
          eventName: '$eventBase.deleted',
          handler: (payload) async => await onDeleted(payload),
        ),
      ];

  Future onCreated(dynamic payload) async {
    print('📥 ${namespace}${displayName} created: \$payload');
  }

  Future onUpdated(dynamic payload) async {
    print('✏️ ${namespace}${displayName} updated: \$payload');
  }

  Future onDeleted(dynamic payload) async {
    print('🗑️ ${namespace}${displayName} deleted: \$payload');
  }
}
''';
  }
}

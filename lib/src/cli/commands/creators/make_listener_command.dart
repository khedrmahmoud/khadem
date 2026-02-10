import 'dart:io';

import '../../../contracts/cli/command.dart';
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
    return '''
import 'package:khadem/contracts.dart';


class $className implements Subscriber {
  @override
  void subscribe(Dispatcher dispatcher) {
    // dispatcher.listen<ModelCreated<User>>(onCreated);

  }

  
  // Future<void> onCreated(ModelCreated<User> event) async {
  //   final user = event.model;
  //   // Handle the event, e.g., send a welcome email
  //   Log.info('User created: \${user.email}');
  // }

 
}
''';
  }
}

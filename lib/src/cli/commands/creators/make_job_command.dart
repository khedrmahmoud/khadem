import 'dart:io';

import '../../bus/command.dart';

class MakeJobCommand extends KhademCommand {
  MakeJobCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Job class name');
  }

  @override
  String get name => 'make:job';

  @override
  String get description => 'Create a new queue job class';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.isEmpty) {
      logger.error('❌ Usage: dart run khadem make:job --name=SendEmail');
      exit(1);
    }

    final className = _capitalize(name.endsWith('Job') ? name : '${name}Job');
    final fileName = '${_snakeCase(className)}.dart';
    final filePath = 'app/jobs/$fileName';

    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString('''
import 'package:khadem/khadem_dart.dart' show QueueJob;

class $className extends QueueJob {
  final String value;

  $className(this.value);

  @override
  Future<void> handle() async {
    // TODO: implement job logic
    print('🧵 Job running with value: \$value');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': runtimeType.toString(),
      'value': value,
    };
  }

  @override
  QueueJob fromJson(Map<String, dynamic> json) {
    return $className(json['value']);
  }
}
''');

    logger.info('✅ Job "$className" created at $filePath');
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

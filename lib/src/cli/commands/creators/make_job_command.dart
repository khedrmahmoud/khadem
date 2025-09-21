import 'dart:io';

import '../../bus/command.dart';

class MakeJobCommand extends KhademCommand {
  MakeJobCommand({required super.logger}) {
    argParser.addOption('name', abbr: 'n', help: 'Job class name (e.g., SendEmail or auth/SendEmailJob)');
  }

  @override
  String get name => 'make:job';

  @override
  String get description => 'Create a new queue job class with optional folder structure';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.isEmpty) {
      logger.error('❌ Usage: khadem make:job --name=JobName or --name=folder/JobName');
      exit(1);
    }

    // Parse folder and job name
    final parts = name.split('/');
    String folder = '';
    String jobName = parts.last;

    if (parts.length > 1) {
      folder = parts.sublist(0, parts.length - 1).join('/');
    }

    // Ensure job name ends with 'Job'
    if (!jobName.endsWith('Job')) {
      jobName = '${jobName}Job';
    }

    final className = _capitalize(jobName);
    final fileName = '${_snakeCase(jobName.replaceAll('Job', ''))}_job.dart';
    final relativePath = folder.isEmpty
        ? 'app/jobs/$fileName'
        : 'app/jobs/$folder/$fileName';

    final file = File(relativePath);
    await file.create(recursive: true);
    await file.writeAsString(_jobStub(className, jobName.replaceAll('Job', ''), folder));

    logger.info('✅ Job "$className" created at "$relativePath"');
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

  String _jobStub(String className, String jobName, String folder) {
    final namespace = folder.isEmpty ? '' : '$folder/';
    return '''
import 'package:khadem/khadem.dart' show QueueJob;

class $className extends QueueJob {
  final String value;

  $className(this.value);

  @override
  Future<void> handle() async {
    // TODO: implement job logic
    print('🧵 ${namespace}$jobName job running with value: \$value');
  }

}
''';
  }
}

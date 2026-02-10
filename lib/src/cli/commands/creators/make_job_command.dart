import 'dart:io';

import '../../../contracts/cli/command.dart';
import '../../utils/cli_naming.dart';

class MakeJobCommand extends KhademCommand {
  MakeJobCommand({required super.logger}) {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Job class name (e.g., SendEmail or auth/SendEmailJob)',
    );
  }

  @override
  String get name => 'make:job';

  @override
  String get description =>
      'Create a new queue job class with optional folder structure';

  @override
  Future<void> handle(List<String> args) async {
    final name = argResults?['name'] as String?;
    if (name == null || name.isEmpty) {
      logger.error(
        '❌ Usage: khadem make:job --name=JobName or --name=folder/JobName',
      );
      exitCode = 1;
      return;
    }

    final parts = CliNaming.splitFolderAndName(name);
    final folder = parts.folder;
    var jobName = parts.name;

    // Ensure job name ends with 'Job'
    jobName = CliNaming.ensureSuffix(CliNaming.toPascalCase(jobName), 'Job');

    final className = jobName;
    final fileName =
        '${CliNaming.toSnakeCase(jobName.replaceAll('Job', ''))}_job.dart';
    final relativePath = folder.isEmpty
        ? 'lib/app/jobs/$fileName'
        : 'lib/app/jobs/$folder/$fileName';

    final file = File(relativePath);
    await file.create(recursive: true);
    await file.writeAsString(
      _jobStub(className, jobName.replaceAll('Job', ''), folder),
    );

    logger.info('✅ Job "$className" created at "$relativePath"');
    exitCode = 0;
    return;
  }

  String _jobStub(String className, String jobName, String folder) {
    final namespace = folder.isEmpty ? '' : '$folder/';
    return '''
import 'package:khadem/contracts.dart';


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

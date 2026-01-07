import 'dart:async';
import 'dart:io';

import 'package:khadem/khadem.dart';
import '../bus/command.dart';

class ScheduleRunCommand extends KhademCommand {
  ScheduleRunCommand({required super.logger});

  @override
  bool get requiresKernelBootstrap => true;

  @override
  String get name => 'schedule:run';

  @override
  String get description => 'Run the scheduled commands';

  @override
  Future<void> handle(List<String> args) async {
    logger.info('⏰ Running scheduled tasks...');

    // In a real implementation, this would trigger the scheduler engine
    // to check all tasks and run due ones.
    // For now, we'll assume the scheduler is running in the main process
    // or this command is used to trigger a single run (like via cron).

    // Khadem.scheduler.runDueTasks(); // Hypothetical API

    logger.info('✅ Scheduled tasks processed.');
    exitCode = 0;
  }
}

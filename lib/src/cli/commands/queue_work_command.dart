import 'dart:async';
import 'dart:io';

import '../../application/khadem.dart';
import '../../core/queue/queue_manager.dart';
import '../bus/command.dart';

class QueueWorkCommand extends KhademCommand {
  @override
  bool get requiresKernelBootstrap => true;

  @override
  String get name => 'queue:work';

  @override
  String get description => 'Start processing queued jobs.';

  QueueWorkCommand({required super.logger}) {
    argParser.addOption('max-jobs', abbr: 'j', help: 'Max jobs to process');
    argParser.addOption(
      'delay',
      abbr: 'd',
      help: 'Delay between jobs (seconds)',
      defaultsTo: '1',
    );
    argParser.addOption('timeout', abbr: 't', help: 'Timeout for processing');
  }

  bool _running = true;

  @override
  Future<void> handle(List<String> args) async {
    final queue = Khadem.container.resolve<QueueManager>();

    // Parse optional args
    final maxJobsRaw = argResults?['max-jobs'] as String?;
    final delayRaw = argResults?['delay'] as String?;
    final timeoutRaw = argResults?['timeout'] as String?;

    final int maxJobs = int.tryParse(maxJobsRaw ?? '') ?? 0;
    final int delaySeconds = int.tryParse(delayRaw ?? '') ?? 1;
    final int timeoutSeconds = int.tryParse(timeoutRaw ?? '') ?? 0;

    int processed = 0;
    final startTime = DateTime.now();

    // Handle Ctrl+C
    ProcessSignal.sigint.watch().listen((_) {
      logger.info('\n👋 Gracefully stopping worker...');
      _running = false;
    });

    logger.info('🚀 Starting queue worker... Press Ctrl+C to stop.');

    while (_running) {
      try {
        await queue.driver.process();
        processed++;

        if (maxJobs > 0 && processed >= maxJobs) {
          logger.info('✅ Max job limit reached ($processed), exiting.');
          break;
        }

        if (timeoutSeconds > 0 &&
            DateTime.now().difference(startTime).inSeconds >= timeoutSeconds) {
          logger.info('⏱ Timeout reached, exiting.');
          break;
        }

        await Future.delayed(Duration(seconds: delaySeconds));
      } catch (e, stack) {
        logger.error('🔥 Error while processing job: $e');
        logger.error(stack.toString());
      }
    }

    logger.info('🛑 Worker stopped. Total jobs processed: $processed');
    exitCode = 0;
    return;
  }
}

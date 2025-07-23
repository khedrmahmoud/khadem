import 'dart:async';
import 'dart:io';

import '../../../application/khadem.dart';
import '../../queue/queue_manager.dart';
import '../bus/command.dart';

class QueueWorkCommand extends KhademCommand {
  @override
  String get name => 'queue:work';

  @override
  String get description => 'Start processing queued jobs.';

  QueueWorkCommand({required super.logger}) {
    argParser.addOption('max-jobs', abbr: 'j', help: 'Max jobs to process');
    argParser.addOption('delay', abbr: 'd', help: 'Delay between jobs');
    argParser.addOption('timeout', abbr: 't', help: 'Timeout for processing');
  }

  bool _running = true;

  @override
  Future<void> handle(List<String> args) async {
    final queue = Khadem.container.resolve<QueueManager>();

    // Parse optional args
    final int maxJobs = _parseArg(args, '--max-jobs', defaultValue: 0);
    final int delaySeconds = _parseArg(args, '--delay', defaultValue: 1);
    final int timeoutSeconds = _parseArg(args, '--timeout', defaultValue: 0);

    int processed = 0;
    final startTime = DateTime.now();

    // Handle Ctrl+C
    ProcessSignal.sigint.watch().listen((_) {
      logger.info('\n👋 Gracefully stopping worker...');
      _running = false;
      exit(0);
    });
    // autoRegisterJobs();

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
    exit(0);
  }

  int _parseArg(List<String> args, String key, {required int defaultValue}) {
    final index = args.indexOf(key);
    if (index != -1 && index + 1 < args.length) {
      return int.tryParse(args[index + 1]) ?? defaultValue;
    }
    return defaultValue;
  }
}

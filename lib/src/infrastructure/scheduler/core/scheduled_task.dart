import 'dart:async';

import '../../../application/khadem.dart';
import '../../../contracts/scheduler/scheduled_job.dart';
import 'job_registry.dart';

class ScheduledTask {
  final String name;
  final Duration interval;
  final ScheduledJob job;
  final String timeZone;
  final bool retryOnFail;
  final bool runOnce;

  Timer? timer;
  bool _isRunning = false;

  ScheduledTask({
    required this.name,
    required this.interval,
    required this.job,
    this.timeZone = 'UTC',
    this.retryOnFail = false,
    this.runOnce = false,
  });

  factory ScheduledTask.fromConfig(Map<String, dynamic> config) {
    final jobName = config['job'];
    final job = SchedulerJobRegistry.resolve(jobName, config);

    if (job == null) {
      throw Exception('Job "$jobName" not found in TaskRunner.');
    }

    if (config['cron'] != null) {
      Khadem.logger.warning(
          '⚠️ Cron expressions are not supported. Task "${config['name']}" will be ignored.');
      throw ArgumentError('Cron is not supported in this version.');
    }

    if (config['interval'] == null) {
      throw ArgumentError(
          'Missing "interval" for scheduled task "${config['name']}"');
    }

    return ScheduledTask(
      name: config['name'],
      interval: Duration(seconds: config['interval']),
      timeZone: config['timezone'] ?? 'UTC',
      job: job,
      retryOnFail: config['retryOnFail'] ?? false,
      runOnce: config['runOnce'] ?? false,
    );
  }

  void start(Function(Duration) scheduleNext) {
    scheduleNext(_nextDelay());
  }

  Duration _nextDelay() {
    return interval;
  }

  Future<void> run(Function(Duration) scheduleNext) async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      await job.execute();
    } catch (e, s) {
      Khadem.logger.error('❌ Error in [$name]: $e\n$s');
      if (retryOnFail) {
        Future.delayed(Duration(seconds: 5), () => run(scheduleNext));
        return;
      }
    } finally {
      _isRunning = false;
    }

    if (!runOnce) {
      final delay = _nextDelay();
      timer = Timer(delay, () => run(scheduleNext));
    }
  }

  void stop() => timer?.cancel();
}

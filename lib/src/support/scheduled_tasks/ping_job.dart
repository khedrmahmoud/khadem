import '../../application/khadem.dart';
import '../../contracts/scheduler/scheduled_job.dart';

class PingJob implements ScheduledJob {
  @override
  String get name => 'ping';

  @override
  Future<void> execute() async {
    Khadem.logger.debug('📡 Ping at ${DateTime.now()}');
    // Add your logic here
  }
}

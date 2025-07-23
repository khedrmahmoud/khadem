import 'dart:convert';
import 'dart:io';

import '../../contracts/scheduler/scheduled_job.dart';
import '../../application/khadem.dart';

class TTLFileCleanerJob implements ScheduledJob {
  @override
  String get name => 'ttl_cache_cleaner';

  final String cachePath;

  TTLFileCleanerJob({required this.cachePath});

  @override
  Future<void> execute() async {
    Khadem.logger.debug('🧹 Executing TTL cache cleanup at ${DateTime.now()}');
    final dir = Directory(cachePath);
    if (!dir.existsSync()) return;

    final files = dir.listSync();

    for (final file in files) {
      if (file is File) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);

          final ttl = data['ttl'];
          final stat = await file.stat();

          if (ttl != null &&
              stat.modified
                  .isBefore(DateTime.now().subtract(Duration(seconds: ttl)))) {
            await file.delete();
            Khadem.logger.info('🧹 Removed expired cache file: ${file.path}');
          }
        } catch (e) {
          Khadem.logger
              .warning('⚠️ Could not process cache file ${file.path}: $e');
        }
      }
    }
  }
}

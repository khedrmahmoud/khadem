import 'dart:io';

import '../../../application/khadem.dart';
import '../bus/command.dart';

class CacheClearCommand extends KhademCommand {
  CacheClearCommand({required super.logger});

  @override
  String get name => 'cache:clear';
  @override
  String get description => 'Clear all cache';

  @override
  Future<void> handle(List<String> args) async {
    await Khadem.cache.clear();
    logger.info('✅ Cache cleared.');
    exit(0);
  }
}

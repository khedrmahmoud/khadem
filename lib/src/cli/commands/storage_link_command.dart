import 'dart:io';

import '../../contracts/cli/command.dart';

class StorageLinkCommand extends KhademCommand {
  StorageLinkCommand({required super.logger});

  @override
  String get name => 'storage:link';

  @override
  String get description =>
      'Create the symbolic links configured for the application';

  @override
  Future<void> handle(List<String> args) async {
    const publicPath = 'public/storage';
    const storagePath = 'storage/app/public';

    final publicLink = Link(publicPath);
    final storageDir = Directory(storagePath);

    if (await publicLink.exists()) {
      logger.error('❌ The "public/storage" link already exists.');
      exitCode = 1;
      return;
    }

    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    try {
      // Note: On Windows, this requires Developer Mode or Admin privileges
      await publicLink.create(storageDir.absolute.path);
      logger.info(
          '✅ The [public/storage] link has been connected to [storage/app/public].',);
      exitCode = 0;
    } catch (e) {
      logger.error('❌ Failed to create symbolic link: $e');
      logger.info(
          '💡 On Windows, you may need to run this command as Administrator or enable Developer Mode.',);
      exitCode = 1;
    }
  }
}

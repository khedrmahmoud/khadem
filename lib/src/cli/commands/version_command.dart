import 'package:khadem/src/cli/bus/command.dart';

import '../../support/utils/package_metadata.dart';

class VersionCommand extends KhademCommand {
  @override
  String get name => 'version';

  @override
  String get description => 'Display the Khadem CLI version information.';

  VersionCommand({required super.logger}) {}

  @override
  Future<void> handle(List<String> args) async {
    final metadata = KhademPackageMetadataLoader.loadSync();

    logger.info('🚀 Khadem Framework CLI');
    logger.info('📦 Version: ${metadata.version}');
    logger.info('🎯 Dart SDK: ${metadata.sdkConstraint}');
    logger.info('📅 Release Date: ${metadata.releaseDate}');
    logger.info('👨‍💻 Developed by: ${metadata.author}');

    logger.info('');
    logger.info('💡 For help, run: khadem --help');
    logger.info('📚 Documentation: ${metadata.documentation}');
  }
}

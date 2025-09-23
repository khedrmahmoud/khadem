import 'package:khadem/src/cli/bus/command.dart';

class VersionCommand extends KhademCommand {
  @override
  String get name => 'version';

  @override
  String get description => 'Display the Khadem CLI version information.';

  VersionCommand({required super.logger}) {}

  @override
  Future<void> handle(List<String> args) async {
    // Static version information
    const version = '1.0.2-beta';

    const documentation = 'https://khadem-framework.github.io/khadem-docs/';
    const releaseDate = 'September 2025';
    const sdkConstraint = '>=3.0.0';

    logger.info('🚀 Khadem Framework CLI');
    logger.info('📦 Version: $version');
    logger.info('🎯 Dart SDK: Compatible with Dart $sdkConstraint');
    logger.info('📅 Release Date: $releaseDate');

    logger.info('');
    logger.info('💡 For help, run: khadem --help');
    logger.info('📚 Documentation: $documentation');
  }
}

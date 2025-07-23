import 'dart:io';

 
import '../../support/providers/cli_service_provider.dart';
import '../../application/khadem.dart';

class CommandBootstrapper {
  static bool _booted = false;

  /// Initializes the Khadem core and loads core providers (for CLI commands).
  static Future<void> register() async {
    if (_booted) return;
    if (_isRunningAsServer()) return;
    _booted = true;
    // Step 2: Register Core CLI-related Providers
    Khadem.register([
      CliServiceProvider(),
    ]);
  }

  static Future<void> boot() async {
    // Step 3: Boot all providers
    await Khadem.providers.bootAll();
    Khadem.logger.info('✅ CLI Bootstrap complete.');
  }

  static bool _isRunningAsServer() {
    return Platform.script.path.contains('server.dart');
  }
}

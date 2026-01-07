import 'dart:io';

import '../application/khadem.dart';
import '../support/providers/cli_service_provider.dart';

class CommandBootstrapper {
  static bool _booted = false;

  /// Initializes the Khadem core and loads core providers (for CLI commands).
  static Future<void> register() async {
    if (Khadem.isBooted) {
      _booted = true;
      return;
    }
    if (_booted) return;
    if (_isRunningAsServer()) return;
    _booted = true;
    // Step 2: Register Core CLI-related Providers
    Khadem.register([
      CliServiceProvider(),
    ]);
  }

  static Future<void> boot() async {
    if (Khadem.isBooted) return;
    // Step 3: Boot all providers
    await Khadem.providers.bootAll();
    Khadem.logger.info('✅ CLI Bootstrap complete.');
  }

  static bool _isRunningAsServer() {
    return Platform.script.path.contains('server.dart');
  }
}

import 'dart:io';
import 'package:khadem/src/cli/cli_entry.dart';

Future<void> main(List<String> args) async {
  // Fast-path: version/help do not need project boot.
  if (args.length == 1 &&
      (args.first == '--version' || args.first == '-v' || args.first == '-V')) {
    exitCode = await runKhademCli(args);
    return;
  }
  // Ensure ConfigSystem does not fail on missing folder.
  final configDir = Directory('config');
  if (!configDir.existsSync()) {
    configDir.createSync(recursive: true);
  }
  // No Kernel/AppConfig detected at install-time. Run without boot, then edit this file.
  final code = await runKhademCli(args);
  exitCode = code;
}

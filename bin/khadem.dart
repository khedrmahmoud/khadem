import 'dart:io';

import 'package:khadem/src/cli/cli_entry.dart';

void main(List<String> args) async {
  if (args.length == 1 &&
      (args.first == '--version' || args.first == '-v' || args.first == '-V')) {
    exitCode = await runKhademCli(args);
    return;
  }

  if (args.isNotEmpty && args.first == 'cli:install') {
    exitCode = await runKhademCli(args);
    return;
  }

  // If a project has a local CLI runner, delegate to it.
  // This is the only reliable way to execute/reflect project code (Kernel,
  // config registries, seeders, etc.) because Dart cannot mirror code that
  // is not imported into the running program.
  const delegateEnv = 'KHADEM_CLI_DELEGATED';
  if (Platform.environment[delegateEnv] != '1') {
    final delegate = File('bin/khadem_cli.dart');
    if (await delegate.exists()) {
      final result = await Process.run(
        'dart',
        ['run', 'bin/khadem_cli.dart', ...args],
        environment: {
          ...Platform.environment,
          delegateEnv: '1',
        },
      );

      stdout.write(result.stdout);
      stderr.write(result.stderr);
      exitCode = result.exitCode;
      return;
    }
  }

  exitCode = await runKhademCli(args);
}

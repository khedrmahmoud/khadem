import 'dart:io';

import 'package:yaml/yaml.dart';

import '../bus/command.dart';

class CliInstallCommand extends KhademCommand {
  CliInstallCommand({required super.logger}) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite bin/khadem_cli.dart if it already exists',
      negatable: false,
    );
  }

  @override
  String get name => 'cli:install';

  @override
  String get description =>
      'Install a project-local CLI runner (enables project-aware commands).';

  @override
  Future<void> handle(List<String> args) async {
    final pubspec = File('pubspec.yaml');
    if (!await pubspec.exists()) {
      logger.error('❌ pubspec.yaml not found in the current directory.');
      exitCode = 1;
      return;
    }

    final projectName = _readProjectName(pubspec);
    if (projectName == null || projectName.trim().isEmpty) {
      logger.error('❌ Could not read project name from pubspec.yaml');
      exitCode = 1;
      return;
    }

    final binDir = Directory('bin');
    if (!await binDir.exists()) {
      await binDir.create(recursive: true);
    }

    final target = File('bin/khadem_cli.dart');
    final force = argResults?['force'] == true;
    if (await target.exists() && !force) {
      logger.warning(
          '⚠️ bin/khadem_cli.dart already exists. Use --force to overwrite.');
      exitCode = 0;
      return;
    }

    final hasKernel = await File('lib/core/kernel.dart').exists();
    final hasAppConfig = await File('lib/config/app.dart').exists();

    final content = _buildRunner(
      projectName: projectName,
      hasKernel: hasKernel,
      hasAppConfig: hasAppConfig,
    );

    await target.writeAsString(content);
    logger.info(
      force ? '✅ Updated bin/khadem_cli.dart' : '✅ Created bin/khadem_cli.dart',
    );

    if (!hasKernel && !hasAppConfig) {
      logger.warning(
          '⚠️ Could not find lib/core/kernel.dart or lib/config/app.dart');
      logger.warning(
        '   Edit bin/khadem_cli.dart to bootstrap your providers/configs before running commands.',
      );
    }

    exitCode = 0;
  }

  String? _readProjectName(File pubspecFile) {
    try {
      final yaml = loadYaml(pubspecFile.readAsStringSync());
      if (yaml is! YamlMap) return null;
      final name = yaml['name'];
      return name is String ? name.replaceAll('"', '').trim() : null;
    } catch (_) {
      return null;
    }
  }

  String _buildRunner({
    required String projectName,
    required bool hasKernel,
    required bool hasAppConfig,
  }) {
    final buffer = StringBuffer();

    buffer.writeln("import 'dart:io';");

    buffer.writeln("import 'package:khadem/src/cli/cli_entry.dart';");

    if (hasKernel) {
      buffer.writeln("import 'package:$projectName/core/kernel.dart';");
    } else if (hasAppConfig) {
      buffer.writeln(
        "import 'package:khadem/khadem.dart' show Khadem, CoreServiceProvider, CacheServiceProvider, QueueServiceProvider, AuthServiceProvider, DatabaseServiceProvider;",
      );
      buffer.writeln("import 'package:$projectName/config/app.dart';");
    }

    buffer.writeln('');
    buffer.writeln('Future<void> main(List<String> args) async {');

    buffer.writeln('  // Fast-path: version/help do not need project boot.');
    buffer.writeln('  if (args.length == 1 &&');
    buffer.writeln(
      "      (args.first == '--version' || args.first == '-v' || args.first == '-V')) {",
    );
    buffer.writeln('    exitCode = await runKhademCli(args);');
    buffer.writeln('    return;');
    buffer.writeln('  }');

    buffer.writeln('  // Ensure ConfigSystem does not fail on missing folder.');
    buffer.writeln("  final configDir = Directory('config');");
    buffer.writeln('  if (!configDir.existsSync()) {');
    buffer.writeln('    configDir.createSync(recursive: true);');
    buffer.writeln('  }');

    buffer.writeln('');
    buffer.writeln('  Future<void> bootstrap() async {');

    if (hasKernel) {
      buffer.writeln('    await Kernel.bootstrap();');
    } else if (hasAppConfig) {
      buffer.writeln('    Khadem.register([');
      buffer.writeln('      CoreServiceProvider(),');
      buffer.writeln('      CacheServiceProvider(),');
      buffer.writeln('      QueueServiceProvider(),');
      buffer.writeln('      AuthServiceProvider(),');
      buffer.writeln('      DatabaseServiceProvider(),');
      buffer.writeln('    ]);');
      buffer.writeln('    Khadem.loadConfigs(AppConfig.configs);');
      buffer.writeln('    await Khadem.boot();');
    } else {
      buffer.writeln(
        '    // No Kernel/AppConfig detected at install-time. Edit this function to bootstrap your providers/configs.',
      );
    }

    buffer.writeln('  }');

    buffer.writeln('');
    buffer.writeln('  final code = await runKhademCli(args, bootstrapKernel: bootstrap);');
    buffer.writeln('  exitCode = code;');
    buffer.writeln('}');

    return buffer.toString();
  }
}

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../core/logging/logger.dart';
import 'bus/command.dart';
import 'commands/build_command.dart';
import 'commands/cache_clear_command.dart';
import 'commands/cli_install_command.dart';
import 'commands/creators/make_command_command.dart';
import 'commands/creators/make_controller_command.dart';
import 'commands/creators/make_event_command.dart';
import 'commands/creators/make_exception_command.dart';
import 'commands/creators/make_job_command.dart';
import 'commands/creators/make_listener_command.dart';
import 'commands/creators/make_mail_command.dart';
import 'commands/creators/make_middleware_command.dart';
import 'commands/creators/make_migration_command.dart';
import 'commands/creators/make_model_command.dart';
import 'commands/creators/make_observer_command.dart';
import 'commands/creators/make_policy_command.dart';
import 'commands/creators/make_provider_command.dart';
import 'commands/creators/make_request_command.dart';
import 'commands/creators/make_resource_command.dart';
import 'commands/creators/make_rule_command.dart';
import 'commands/creators/make_seeder_command.dart';
import 'commands/creators/make_test_command.dart';
import 'commands/creators/make_view_command.dart';
import 'commands/doctor_command.dart';
import 'commands/key_generate_command.dart';
import 'commands/logs_clear_command.dart';
import 'commands/migrate_command.dart';
import 'commands/new_command.dart';
import 'commands/queue_work_command.dart';
import 'commands/routes_list_command.dart';
import 'commands/schedule_run_command.dart';
import 'commands/seed_command.dart';
import 'commands/serve_command.dart';
import 'commands/storage_link_command.dart';
import 'commands/version_command.dart';

/// Core registry to manage and load CLI commands.
class CommandRegistry {
  final Logger logger;
  final List<KhademCommand> _coreCommands = [];
  final List<KhademCommand> _customCommands = [];
  String? _packageName;

  CommandRegistry(this.logger) {
    _registerCoreCommands();
  }

  void _registerCoreCommands() {
    if (_coreCommands.isNotEmpty) return;

    _coreCommands.addAll([
      DoctorCommand(logger: logger),
      NewCommand(logger: logger),
      CliInstallCommand(logger: logger),
      // Creators
      MakeModelCommand(logger: logger),
      MakeMigrationCommand(logger: logger),
      MakeControllerCommand(logger: logger),
      MakeCommandCommand(logger: logger),
      MakeMiddlewareCommand(logger: logger),
      MakeProviderCommand(logger: logger),
      MakeListenerCommand(logger: logger),
      MakeJobCommand(logger: logger),
      MakeEventCommand(logger: logger),
      MakeObserverCommand(logger: logger),
      MakeSeederCommand(logger: logger),
      MakeViewCommand(logger: logger),
      MakePolicyCommand(logger: logger),
      MakeRequestCommand(logger: logger),
      MakeResourceCommand(logger: logger),
      MakeExceptionCommand(logger: logger),
      MakeMailCommand(logger: logger),
      MakeTestCommand(logger: logger),
      MakeRuleCommand(logger: logger),
      //
      ServeCommand(logger: logger),
      BuildCommand(logger: logger),
      VersionCommand(logger: logger),
      KeyGenerateCommand(logger: logger),
      StorageLinkCommand(logger: logger),
      ScheduleRunCommand(logger: logger),
      // Developer helpers
      CacheClearCommand(logger: logger),
      LogsClearCommand(logger: logger),
      RoutesListCommand(logger: logger),
      //
      MigrateCommand(logger: logger),
      DbSeedCommand(logger: logger),
      QueueWorkCommand(logger: logger),
    ]);
  }

  /// Register additional custom CLI commands (e.g., from plugins).
  void registerCustom(KhademCommand command) {
    registerCustomCommand(command);
  }

  /// Programmatic API for external projects to register custom commands.
  /// This is the recommended way for external projects to add commands.
  void registerCustomCommand(KhademCommand command) {
    // Avoid duplicates by command name.
    if (_customCommands.any((c) => c.name == command.name)) return;
    _customCommands.add(command);
    logger.info('✅ Registered custom command: ${command.name}');
  }

  /// Returns close matches for a command name (for smarter UX on typos).
  List<String> suggestCommands(String input, {int limit = 3}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const [];

    final names = commands.map((c) => c.name).toSet().toList();
    names.sort();

    final scored = <({String name, int score})>[];
    for (final name in names) {
      scored.add((name: name, score: _levenshtein(trimmed, name)));
    }

    scored.sort((a, b) => a.score.compareTo(b.score));
    return scored.take(limit).map((e) => e.name).toList();
  }

  /// Auto-discover and register custom commands from the user's project using mirrors.
  Future<void> autoDiscoverCommands(String projectPath) async {
    // dart:mirrors is not supported in AOT and is unreliable for discovering
    // project code unless it is explicitly imported. Prefer installing a
    // project-local runner via `cli:install` and registering commands
    // programmatically in that runner.
    await _loadPackageName();
    logger.debug(
      'autoDiscoverCommands is disabled (dart:mirrors removed). Register custom commands programmatically.',
    );
  }

  /// Load the package name from pubspec.yaml.
  Future<void> _loadPackageName() async {
    try {
      final pubspecFile =
          File(path.join(Directory.current.path, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) {
        _packageName = path.basename(Directory.current.path);
        return;
      }

      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content) as Map<dynamic, dynamic>;
      _packageName = yaml['name'] as String?;

      if (_packageName == null) {
        _packageName = path.basename(Directory.current.path);
      }
    } catch (e) {
      _packageName = path.basename(Directory.current.path);
    }
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final aLen = a.length;
    final bLen = b.length;

    var prev = List<int>.generate(bLen + 1, (i) => i);
    var curr = List<int>.filled(bLen + 1, 0);

    for (var i = 1; i <= aLen; i++) {
      curr[0] = i;
      final aChar = a.codeUnitAt(i - 1);

      for (var j = 1; j <= bLen; j++) {
        final cost = aChar == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = prev[j] + 1;
        final insertion = curr[j - 1] + 1;
        final substitution = prev[j - 1] + cost;
        curr[j] = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
      }

      final tmp = prev;
      prev = curr;
      curr = tmp;
    }

    return prev[bLen];
  }

  /// Get all registered commands (core + custom).
  List<KhademCommand> get commands => [..._coreCommands, ..._customCommands];

  /// Get only core commands.
  List<KhademCommand> get coreCommands => _coreCommands;

  /// Get only custom commands.
  List<KhademCommand> get customCommands => _customCommands;
}

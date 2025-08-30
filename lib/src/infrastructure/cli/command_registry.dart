import '../logging/logger.dart';
import 'bus/command.dart';
import 'commands/creators/make_controller_command.dart';
import 'commands/creators/make_job_command.dart';
import 'commands/creators/make_listener_command.dart';
import 'commands/creators/make_middleware_command.dart';
import 'commands/creators/make_migration_command.dart';
import 'commands/creators/make_model_command.dart';
import 'commands/creators/make_provider_command.dart';
// import 'commands/docker_build_command.dart';
import 'commands/new_command.dart';
import 'commands/serve_command.dart';
// import 'commands/migrate_command.dart';
// import 'commands/seed_command.dart';
// import 'commands/queue_work_command.dart';
// import 'commands/cache_clear_command.dart';

/// Core registry to manage and load CLI commands.
class CommandRegistry {
  final Logger logger;
  final List<KhademCommand> _coreCommands = [];

  CommandRegistry(this.logger) {
    _registerCoreCommands();
  }

  void _registerCoreCommands() {
    _coreCommands.addAll([
      NewCommand(logger: logger),
      // Creators
      MakeModelCommand(logger: logger),
      MakeMigrationCommand(logger: logger),
      MakeControllerCommand(logger: logger),
      MakeMiddlewareCommand(logger: logger),
      MakeProviderCommand(logger: logger),
      MakeListenerCommand(logger: logger),
      MakeJobCommand(logger: logger),
      //
      ServeCommand(logger: logger),
      // WatchCommand(logger: logger),
      //
      // BuildCommand(logger: logger),
      // DockerBuildCommand(logger: logger),
      
       //
      // MigrateCommand(logger: logger),
      // DbSeedCommand(logger: logger),
      // QueueWorkCommand(logger: logger),
      // CacheClearCommand(logger: logger),
    ]);
  }

  /// Register additional custom CLI commands (e.g., from plugins).
  void registerCustom(KhademCommand command) {
    _coreCommands.add(command);
  }

  List<KhademCommand> get commands => _coreCommands;
}

import '../../contracts/cli/command.dart';

class CommandsCommand extends KhademCommand {
  final List<({String name, String description})> _commands;

  CommandsCommand({
    required super.logger,
    required List<KhademCommand> commands,
  }) : _commands = commands
           .map((c) => (name: c.name, description: c.description))
           .toList();

  @override
  String get name => 'commands';

  @override
  String get description => 'List all available Khadem CLI commands.';

  @override
  Future<void> handle(List<String> args) async {
    final rows = [..._commands]..sort((a, b) => a.name.compareTo(b.name));

    logger.info('Available commands:');
    for (final row in rows) {
      final padded = row.name.padRight(18);
      logger.info('  $padded ${row.description}');
    }

    exitCode = 0;
  }
}

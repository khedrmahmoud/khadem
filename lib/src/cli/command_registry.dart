import 'dart:io';
import 'dart:mirrors';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../core/logging/logger.dart';
import '../contracts/cli/command.dart';
import 'commands/build_command.dart';
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
 import 'commands/creators/make_provider_command.dart';
import 'commands/creators/make_request_command.dart';
import 'commands/creators/make_rule_command.dart';
import 'commands/creators/make_seeder_command.dart';
import 'commands/creators/make_test_command.dart';
import 'commands/creators/make_view_command.dart';

import 'commands/new_command.dart';

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
      NewCommand(logger: logger),
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
       MakeRequestCommand(logger: logger),
      MakeExceptionCommand(logger: logger),
      MakeMailCommand(logger: logger),
      MakeTestCommand(logger: logger),
      MakeRuleCommand(logger: logger),
      //
      ServeCommand(logger: logger),
      BuildCommand(logger: logger),
      VersionCommand(logger: logger),
      StorageLinkCommand(logger: logger),
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
    try {
      await _loadPackageName();

      final commandsDir = Directory(path.join(projectPath, 'app', 'commands'));
      if (!await commandsDir.exists()) {
        return;
      }

      final commandFiles = await _findCommandFiles(commandsDir);
      for (final file in commandFiles) {
        // Try mirror-based loading
        await _tryLoadCommandWithMirrors(file);
      }
    } catch (e) {
      logger.warning('Failed to auto-discover commands: $e');
    }
  }

  /// Find all Dart files that might contain command classes.
  Future<List<File>> _findCommandFiles(Directory commandsDir) async {
    final files = <File>[];

    await for (final entity in commandsDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final base = path.basename(entity.path).toLowerCase();
        if (!base.endsWith('_command.dart')) {
          continue;
        }
        // Skip core command files
        if (!entity.path.contains('core') &&
            !entity.path.contains('creators')) {
          files.add(entity);
        }
      }
    }

    return files;
  }

  /// Try to load a command using mirrors.
  Future<bool> _tryLoadCommandWithMirrors(File file) async {
    try {
      final filePath = file.path;

      // Try multiple loading strategies
      LibraryMirror? library;

      // Strategy 1: Try package URI (works for same project)
      if (_packageName == 'khadem' ||
          _packageName == path.basename(Directory.current.path)) {
        final libraryName = _getLibraryName(filePath);
        library = await _loadLibrary(libraryName);
      }

      // Strategy 2: Try file URI (works for external projects)
      library ??= await _loadLibraryFromFile(filePath);

      if (library == null) return false;

      // Find command classes in the library
      final commandClasses = _findCommandClasses(library);

      for (final classMirror in commandClasses) {
        final commandInstance = _instantiateCommand(classMirror);
        if (commandInstance != null) {
          _customCommands.add(commandInstance);
          logger.info(
            '✅ Auto-registered custom command: ${commandInstance.name}',
          );
        }
      }

      return commandClasses.isNotEmpty;
    } catch (e) {
      logger.debug('Mirror loading failed for ${file.path}: $e');
      return false;
    }
  }

  /// Get library name from file path.
  String _getLibraryName(String filePath) {
    // Convert file path to library URI
    final relativePath = path.relative(filePath, from: Directory.current.path);
    final libraryPath = relativePath.replaceAll('\\', '/');
    final packageName = _packageName ?? path.basename(Directory.current.path);
    return 'package:$packageName/${libraryPath}';
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

  /// Load a library using mirrors with fallback strategies.
  Future<LibraryMirror?> _loadLibrary(String libraryName) async {
    try {
      final libraryUri = Uri.parse(libraryName);
      final library = await currentMirrorSystem().isolate.loadUri(libraryUri);
      return library;
    } catch (e) {
      // Try alternative loading strategies for external projects
      return _tryAlternativeLibraryLoad(libraryName);
    }
  }

  /// Load a library directly from a file path using mirrors.
  Future<LibraryMirror?> _loadLibraryFromFile(String filePath) async {
    try {
      // Convert file path to file URI
      final fileUri = Uri.file(filePath);

      final library = await currentMirrorSystem().isolate.loadUri(fileUri);
      return library;
    } catch (e) {
      return null;
    }
  }

  /// Try alternative library loading strategies for external projects.
  Future<LibraryMirror?> _tryAlternativeLibraryLoad(String libraryName) async {
    try {
      // Extract the relative path from the package URI
      final uri = Uri.parse(libraryName);
      if (uri.scheme == 'package') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          // Try loading as a file URI relative to current directory
          final relativePath = pathSegments.join('/');
          final filePath = path.join(Directory.current.path, relativePath);

          if (await File(filePath).exists()) {
            final fileUri = Uri.file(filePath);
            return currentMirrorSystem().isolate.loadUri(fileUri);
          }
        }
      }
    } catch (e) {
      logger.debug('Alternative library loading failed: $e');
    }

    return null;
  }

  /// Find all classes that extend KhademCommand.
  List<ClassMirror> _findCommandClasses(LibraryMirror library) {
    final commandClasses = <ClassMirror>[];
    for (final declaration in library.declarations.values) {
      if (declaration is ClassMirror) {
        // Check if the class extends KhademCommand
        if (_isCommandClass(declaration)) {
          commandClasses.add(declaration);
        }
      }
    }

    return commandClasses;
  }

  /// Check if a class extends KhademCommand.
  bool _isCommandClass(ClassMirror classMirror) {
    var currentClass = classMirror;

    // Walk up the inheritance hierarchy
    while (currentClass.superclass != null) {
      final superClassName =
          MirrorSystem.getName(currentClass.superclass!.simpleName);

      if (superClassName == 'KhademCommand') {
        return true;
      }

      currentClass = currentClass.superclass!;
    }

    return false;
  }

  /// Instantiate a command class.
  KhademCommand? _instantiateCommand(ClassMirror classMirror) {
    try {
      // Try different instantiation strategies
      InstanceMirror? instance;

      // Strategy 1: Try with named parameter {logger: logger}
      try {
        instance = classMirror.newInstance(
          const Symbol(''),
          [],
          {const Symbol('logger'): logger},
        );
      } catch (e) {
        // Strategy 2: Try with positional parameter [logger]
        try {
          instance = classMirror.newInstance(const Symbol(''), [logger]);
        } catch (e2) {
          // Strategy 3: Try with no parameters (might have default values)
          try {
            instance = classMirror.newInstance(const Symbol(''), []);
          } catch (e3) {
            // All strategies failed
            return null;
          }
        }
      }

      if (instance.reflectee is KhademCommand) {
        final command = instance.reflectee as KhademCommand;
        return command;
      }

      return null;
    } catch (e) {
      return null;
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

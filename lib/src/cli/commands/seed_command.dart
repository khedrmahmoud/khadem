import 'dart:io';
import 'dart:mirrors';

import 'package:path/path.dart' as path;

import '../../application/khadem.dart';
import '../../contracts/database/seeder.dart';
import '../../core/database/migration/seeder.dart';
import '../bus/command.dart';
import '../command_bootstrapper.dart';

class DbSeedCommand extends KhademCommand {
  @override
  String get name => 'db:seed';

  @override
  String get description => 'Run database seeders with automatic discovery';

  DbSeedCommand({required super.logger}) {
    argParser
      ..addFlag('force',
          abbr: 'f',
          help: 'Force run seeders in production',
          negatable: false,)
      ..addOption('class',
          abbr: 'c',
          help: 'Run a specific seeder class',
          valueHelp: 'className',)
      ..addFlag('verbose',
          abbr: 'v',
          help: 'Show detailed seeder information',
          negatable: false,);
  }

  @override
  Future<void> handle(List<String> args) async {
    try {
    await CommandBootstrapper.register();
      await CommandBootstrapper.boot();
      // Check if we're in production without force flag
      final isProduction = Khadem.isProduction;
      final force = argResults?['force'] == true;

      if (isProduction && !force) {
        logger.error('❌ Production environment detected!');
        logger.error('💡 Use --force flag to run seeders in production');
        logger.error('⚠️  This can be dangerous. Make sure you have backups!');
        exit(1);
      }

      final seederManager = Khadem.container.resolve<SeederManager>();

      // Auto-discover and register seeders using Dart mirrors
      await _autoDiscoverSeeders(seederManager);

      final specificClass = argResults?['class'] as String?;

      if (specificClass != null) {
        await _runSpecificSeeder(seederManager, specificClass);
      } else {
        await _runAllSeeders(seederManager);
      }

      logger.info('✅ Database seeding completed successfully.');
      exit(0);

    } catch (e, stackTrace) {
      logger.error('❌ Seeding failed: $e');
      if (argResults?['verbose'] == true) {
        logger.error('Stack trace: $stackTrace');
      }
      logger.error('💡 Try running with --verbose for more details');
      exit(1);
    }
  }

  Future<void> _autoDiscoverSeeders(SeederManager seederManager) async {
    try {
      logger.info('🔍 Auto-discovering seeders using Dart mirrors...');

      // Try to load seeders from seeders.dart registry first
      final registrySeeders = await _loadSeedersFromRegistry();
      if (registrySeeders.isNotEmpty) {
        seederManager.registerAll(registrySeeders);
        logger.info('✅ Loaded ${registrySeeders.length} seeders from registry');
        return;
      }

      // Fallback: Discover seeder files manually
      logger.info('📂 Falling back to manual seeder discovery...');
      final manualSeeders = await _discoverSeedersManually();
      seederManager.registerAll(manualSeeders);
      logger.info('✅ Discovered ${manualSeeders.length} seeders manually');

    } catch (e, stackTrace) {
      logger.error('❌ Failed to auto-discover seeders: $e');
      if (argResults?['verbose'] == true) {
        logger.error('Stack trace: $stackTrace');
      }
      logger.warning('⚠️ Continuing without auto-discovery...');
    }
  }

  Future<List<Seeder>> _loadSeedersFromRegistry() async {
    try {
      const seedersPath = 'database/seeders/seeders.dart';
      final seedersFile = File(seedersPath);

      if (!await seedersFile.exists()) {
        if (argResults?['verbose'] == true) {
          logger.info('📄 seeders.dart registry not found at $seedersPath');
        }
        return [];
      }

      logger.info('🔧 Loading seeders from registry...');

      // Read the registry file
      final content = await seedersFile.readAsString();

      // Extract seeder class names from the registry using simple string parsing
      final lines = content.split('\n');
      final seederClasses = <String>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.contains('() =>') && trimmed.contains('Seeder(')) {
          // Extract class name from pattern like: () => UserSeeder('')
          final startIndex = trimmed.indexOf('=> ') + 3;
          final endIndex = trimmed.indexOf('(', startIndex);
          if (startIndex > 2 && endIndex > startIndex) {
            final className = trimmed.substring(startIndex, endIndex);
            seederClasses.add(className);
          }
        }
      }

      if (seederClasses.isEmpty) {
        logger.warning('⚠️ No seeder classes found in registry');
        return [];
      }

      if (argResults?['verbose'] == true) {
        logger.info('📋 Found seeder classes: $seederClasses');
      }

      // Instantiate seeders using mirrors
      final seeders = <Seeder>[];
      for (final className in seederClasses) {
        try {
          final seeder = await _instantiateSeederWithMirror(className);
          if (seeder != null) {
            seeders.add(seeder);
            if (argResults?['verbose'] == true) {
              logger.info('✅ Instantiated seeder: $className');
            }
          }
        } catch (e) {
          logger.error('❌ Failed to instantiate seeder: $className');
          logger.error('   Error: $e');
          if (argResults?['verbose'] == true) {
            rethrow;
          }
        }
      }

      return seeders;

    } catch (e) {
      logger.error('❌ Failed to load seeders registry: $e');
      return [];
    }
  }

  Future<List<Seeder>> _discoverSeedersManually() async {
    final seedersDir = Directory('database/seeders');
    if (!await seedersDir.exists()) {
      logger.warning('⚠️ Seeders directory not found: database/seeders');
      return [];
    }

    final seeders = <Seeder>[];
    await for (final entity in seedersDir.list()) {
      if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('seeders.dart')) {
        try {
          final seeder = await _loadSeederFromFile(entity);
          if (seeder != null) {
            seeders.add(seeder);
            if (argResults?['verbose'] == true) {
              logger.info('📄 Loaded seeder: ${path.basenameWithoutExtension(entity.path)}');
            }
          }
        } catch (e) {
          logger.error('❌ Failed to load seeder: ${entity.path}');
          logger.error('   Error: $e');
          if (argResults?['verbose'] == true) {
            rethrow;
          }
        }
      }
    }

    return seeders;
  }

  Future<Seeder?> _loadSeederFromFile(File file) async {
    try {
      final className = await _extractSeederClassFromFile(file);
      if (className == null) return null;

      return await _instantiateSeederWithMirror(className);
    } catch (e) {
      logger.error('❌ Failed to load seeder from file: ${file.path}');
      logger.error('   Error: $e');
      return null;
    }
  }

  Future<String?> _extractSeederClassFromFile(File file) async {
    try {
      final content = await file.readAsString();
      final classPattern = RegExp(r'class\s+(\w+)\s+extends\s+Seeder');
      final match = classPattern.firstMatch(content);
      return match?.group(1);
    } catch (e) {
      logger.error('❌ Failed to extract class from ${file.path}: $e');
      return null;
    }
  }

  Future<Seeder?> _instantiateSeederWithMirror(String className) async {
    try {
      // Get the mirror system
      final mirrorSystem = currentMirrorSystem();

      // Find the library that contains the seeder class
      ClassMirror? seederClassMirror;

      for (final library in mirrorSystem.libraries.values) {
        try {
          seederClassMirror = library.declarations[Symbol(className)] as ClassMirror?;
          if (seederClassMirror != null) {
            break;
          }
        } catch (e) {
          // Continue searching
        }
      }

      if (seederClassMirror == null) {
        logger.warning('⚠️ Seeder class "$className" not found in mirror system');
        logger.warning('   This may be normal if the class hasn\'t been imported');
        return null;
      }

      // Check if it extends Seeder
      final seederType = reflectType(Seeder);
      if (!seederClassMirror.isSubtypeOf(seederType)) {
        logger.warning('⚠️ Class "$className" does not extend Seeder');
        return null;
      }

      // Create an instance using the default constructor
      final instanceMirror = seederClassMirror.newInstance(const Symbol(''), []);
      final seeder = instanceMirror.reflectee as Seeder;

      return seeder;

    } catch (e) {
      logger.error('❌ Failed to instantiate seeder with mirror: $className');
      logger.error('   Error: $e');
      return null;
    }
  }

  Future<void> _runAllSeeders(SeederManager seederManager) async {
    logger.info('🚀 Running all seeders...');
    await seederManager.runAll();
  }

  Future<void> _runSpecificSeeder(SeederManager seederManager, String className) async {
    logger.info('🎯 Running specific seeder: $className');
    await seederManager.run(className);
  }
}

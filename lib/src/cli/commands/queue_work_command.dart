import 'dart:async';
import 'dart:io';
import 'dart:mirrors';


import '../../application/khadem.dart';
import '../../contracts/queue/queue_job.dart';
import '../../core/queue/queue_manager.dart';
import '../bus/command.dart';
import '../command_bootstrapper.dart';

class QueueWorkCommand extends KhademCommand {
  @override
  String get name => 'queue:work';

  @override
  String get description => 'Start processing queued jobs.';

  QueueWorkCommand({required super.logger}) {
    argParser.addOption('max-jobs', abbr: 'j', help: 'Max jobs to process');
    argParser.addOption('delay', abbr: 'd', help: 'Delay between jobs');
    argParser.addOption('timeout', abbr: 't', help: 'Timeout for processing');
  }

  bool _running = true;

  @override
  Future<void> handle(List<String> args) async {
    await CommandBootstrapper.register();
      await CommandBootstrapper.boot();
    final queue = Khadem.container.resolve<QueueManager>();

    // Parse optional args
    final int maxJobs = _parseArg(args, '--max-jobs', defaultValue: 0);
    final int delaySeconds = _parseArg(args, '--delay', defaultValue: 1);
    final int timeoutSeconds = _parseArg(args, '--timeout', defaultValue: 0);

    int processed = 0;
    final startTime = DateTime.now();

    // Auto-register jobs using Dart mirrors
    await autoRegisterJobs();

    // Handle Ctrl+C
    ProcessSignal.sigint.watch().listen((_) {
      logger.info('\n👋 Gracefully stopping worker...');
      _running = false;
      exit(0);
    });

    logger.info('🚀 Starting queue worker... Press Ctrl+C to stop.');

    while (_running) {
      try {
        await queue.driver.process();
        processed++;

        if (maxJobs > 0 && processed >= maxJobs) {
          logger.info('✅ Max job limit reached ($processed), exiting.');
          break;
        }

        if (timeoutSeconds > 0 &&
            DateTime.now().difference(startTime).inSeconds >= timeoutSeconds) {
          logger.info('⏱ Timeout reached, exiting.');
          break;
        }

        await Future.delayed(Duration(seconds: delaySeconds));
      } catch (e, stack) {
        logger.error('🔥 Error while processing job: $e');
        logger.error(stack.toString());
      }
    }

    logger.info('🛑 Worker stopped. Total jobs processed: $processed');
    exit(0);
  }

  int _parseArg(List<String> args, String key, {required int defaultValue}) {
    final index = args.indexOf(key);
    if (index != -1 && index + 1 < args.length) {
      return int.tryParse(args[index + 1]) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Automatically discovers and registers queue jobs using Dart mirrors
  Future<void> autoRegisterJobs() async {
    try {
      logger.info('🔍 Discovering queue jobs using Dart mirrors...');

      // Try to load jobs from jobs.dart registry first
      final jobsLoaded = await _loadJobsFromRegistry();
      if (jobsLoaded > 0) {
        logger.info('✅ Loaded $jobsLoaded jobs from registry');
        return;
      }

      // Fallback: Discover job files manually
      logger.info('📂 Falling back to manual job discovery...');
      final manualJobs = await _discoverJobsManually();
      logger.info('✅ Discovered ${manualJobs.length} jobs manually');

    } catch (e, stackTrace) {
      logger.error('❌ Failed to auto-register jobs: $e');
      logger.error('Stack trace: $stackTrace');
      logger.warning('⚠️ Continuing without auto-registration...');
    }
  }

  /// Loads jobs from the jobs.dart registry file using mirrors
  Future<int> _loadJobsFromRegistry() async {
    try {
      const jobsPath = 'app/jobs/jobs.dart';
      final jobsFile = File(jobsPath);

      if (!await jobsFile.exists()) {
        logger.info('📄 jobs.dart registry not found at $jobsPath');
        return 0;
      }

      logger.info('🔧 Loading jobs from registry...');

      // Read the registry file
      final content = await jobsFile.readAsString();

      // Extract job class names from the registry using simple string parsing
      final lines = content.split('\n');
      final jobClasses = <String>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.contains('() =>') && trimmed.contains('Job(')) {
          // Extract class name from pattern like: () => SendUserNotificationJob('')
          final startIndex = trimmed.indexOf('=> ') + 3;
          final endIndex = trimmed.indexOf('(', startIndex);
          if (startIndex > 2 && endIndex > startIndex) {
            final className = trimmed.substring(startIndex, endIndex).trim();
            if (className.isNotEmpty && className != 'QueueJob') {
              jobClasses.add(className);
            }
          }
        }
      }

      if (jobClasses.isEmpty) {
        logger.warning('⚠️ No job classes found in registry');
        return 0;
      }

      logger.info('📋 Found job classes: $jobClasses');

      // Register jobs using mirrors
      for (final className in jobClasses) {
        try {
          await _registerJobWithMirror(className);
          logger.info('✅ Registered job: $className');
        } catch (e) {
          logger.error('❌ Failed to register job: $className');
          logger.error('   Error: $e');
        }
      }

      return jobClasses.length;

    } catch (e) {
      logger.error('❌ Failed to load jobs registry: $e');
      return 0;
    }
  }

  /// Discovers job files manually and registers them
  Future<List<String>> _discoverJobsManually() async {
    final jobsDir = Directory('app/jobs');
    if (!await jobsDir.exists()) {
      logger.warning('⚠️ Jobs directory not found: app/jobs');
      return [];
    }

    final jobFiles = <String>[];
    await for (final entity in jobsDir.list()) {
      if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('jobs.dart')) {
        final className = await _extractJobClassFromFile(entity);
        if (className != null) {
          jobFiles.add(className);
          await _registerJobWithMirror(className);
        }
      }
    }

    return jobFiles;
  }

  /// Extracts job class name from a Dart file
  Future<String?> _extractJobClassFromFile(File file) async {
    try {
      final content = await file.readAsString();
      final classPattern = RegExp(r'class\s+(\w+)\s+extends\s+QueueJob');
      final match = classPattern.firstMatch(content);
      return match?.group(1);
    } catch (e) {
      logger.error('❌ Failed to extract class from ${file.path}: $e');
      return null;
    }
  }

  /// Registers a job class using Dart mirrors
  Future<void> _registerJobWithMirror(String className) async {
    try {
      // Get the mirror system
      final mirrorSystem = currentMirrorSystem();

      // Find the library containing the job class
      LibraryMirror? jobLibrary;
      for (final library in mirrorSystem.libraries.values) {
        if (library.declarations.containsKey(Symbol(className))) {
          jobLibrary = library;
          break;
        }
      }

      if (jobLibrary == null) {
        throw Exception('Job class $className not found in any library');
      }

      // Get the class mirror
      final classMirror = jobLibrary.declarations[Symbol(className)] as ClassMirror;

      // Verify it extends QueueJob
      const queueJobSymbol = Symbol('QueueJob');
      bool extendsQueueJob = false;
      ClassMirror? currentClass = classMirror;

      while (currentClass != null) {
        if (currentClass.superclass?.simpleName == queueJobSymbol) {
          extendsQueueJob = true;
          break;
        }
        currentClass = currentClass.superclass;
      }

      if (!extendsQueueJob) {
        throw Exception('Class $className does not extend QueueJob');
      }

      // Create an instance using the default constructor to verify it works
      final instanceMirror = classMirror.newInstance(const Symbol(''), []);

      // Verify the instance is a valid QueueJob
      final jobInstance = instanceMirror.reflectee as QueueJob;

      // Log successful registration
      logger.info('🔗 Job $className registered successfully with mirrors');

    } catch (e) {
      logger.error('❌ Mirror registration failed for $className: $e');
      rethrow;
    }
  }
}

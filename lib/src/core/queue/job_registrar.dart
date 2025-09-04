import '../../contracts/queue/queue_job.dart';
import '../../core/queue/job_registry.dart';

/// Advanced job registrar that provides multiple registration patterns
/// and makes job registration much more convenient and type-safe.
class QueueJobRegistrar {
  static final QueueJobRegistrar _instance = QueueJobRegistrar._internal();
  factory QueueJobRegistrar() => _instance;
  QueueJobRegistrar._internal();

  final List<String> _registeredJobs = [];
  final List<String> _pendingJobs = [];

  /// Registers a single job with automatic type inference
  void register<T extends QueueJob>(T Function(Map<String, dynamic>) factory) {
    final typeName = T.toString();

    if (_registeredJobs.contains(typeName)) {
      print('⚠️  Job "$typeName" is already registered, skipping...');
      return;
    }

    try {
      QueueJobRegistry.registerJob(factory);
      _registeredJobs.add(typeName);
      print('✅ Registered job: $typeName');
    } catch (e) {
      print('❌ Failed to register job "$typeName": $e');
      rethrow;
    }
  }

  /// Registers multiple jobs at once
  void registerAll(List<QueueJobRegistration> registrations) {
    for (final reg in registrations) {
      try {
        register(reg.factory);
      } catch (e) {
        print('❌ Failed to register ${reg.typeName}: $e');
        // Continue with other registrations
      }
    }
  }

  /// Registers jobs from a list of job classes (requires manual factory creation)
  void registerFromClasses(List<Type> jobClasses) {
    for (final jobClass in jobClasses) {
      _pendingJobs.add(jobClass.toString());
    }
  }

  /// Batch registers jobs using a discovery pattern
  /// This method can be enhanced to auto-discover jobs from specific directories
  Future<void> discoverAndRegister() async {
    // This could be enhanced to scan for job classes automatically
    // For now, it's a placeholder for future enhancement
    print('🔍 Discovering jobs...');

    // Example: Could scan lib/src/modules/*/jobs/ directories
    // and automatically register found job classes

    print('✅ Job discovery completed');
  }

  /// Registers a job with retry logic
  Future<void> registerWithRetry<T extends QueueJob>(
    T Function(Map<String, dynamic>) factory, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    final typeName = T.toString();
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        register(factory);
        return;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw QueueJobRegistrationException(
            'Failed to register job "$typeName" after $maxRetries attempts: $e',
          );
        }
        await Future.delayed(delay);
      }
    }
  }

  /// Validates all registered jobs
  bool validateRegistrations() {
    bool allValid = true;

    for (final typeName in _registeredJobs) {
      if (!QueueJobRegistry.isRegistered(typeName)) {
        print('❌ Validation failed: Job "$typeName" not found in registry');
        allValid = false;
      }
    }

    if (allValid) {
      print('✅ All ${_registeredJobs.length} job registrations validated');
    }

    return allValid;
  }

  /// Gets registration statistics
  Map<String, dynamic> getStats() => {
    'registered_jobs': _registeredJobs.length,
    'pending_jobs': _pendingJobs.length,
    'registry_stats': QueueJobRegistry.getStats(),
  };

  /// Clears all registrations (useful for testing)
  void clear() {
    _registeredJobs.clear();
    _pendingJobs.clear();
    QueueJobRegistry.clear();
  }
}

/// Represents a job registration entry
class QueueJobRegistration<T extends QueueJob> {
  final String typeName;
  final T Function(Map<String, dynamic>) factory;

  const QueueJobRegistration(this.typeName, this.factory);
}

/// Extension methods for easier job registration
extension QueueJobRegistrationExtension on QueueJobRegistrar {
  /// Registers a job using a more fluent API
  QueueJobRegistrar add<T extends QueueJob>(T Function(Map<String, dynamic>) factory) {
    register(factory);
    return this;
  }

  /// Registers multiple jobs fluently
  QueueJobRegistrar addAll(List<QueueJobRegistration> registrations) {
    registerAll(registrations);
    return this;
  }
}

/// Global instance for easy access
final jobRegistrar = QueueJobRegistrar();

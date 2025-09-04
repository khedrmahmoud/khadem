

import 'package:khadem/src/core/queue/job_registry.dart';
import 'package:khadem/src/core/queue/job_registrar.dart';

/// Represents a job that can be queued and processed asynchronously.
/// 
/// Every job must implement [handle] for logic execution,
/// and provide serialization via [toJson] and [fromJson] to allow persistence.
///

abstract class QueueJob   {

   
  /// Called when the job is executed.
  Future<void> handle();

  /// Converts this job instance to JSON for storage.
  Map<String, dynamic> toJson();

  /// Rebuilds this job instance from JSON.
  /// Note: Concrete implementations should return their own type
  QueueJob fromJson(Map<String, dynamic> json);



}
/// Enhanced mixin that provides automatic job registration.
/// Jobs using this mixin will be automatically registered when first instantiated.
mixin AutoRegisterQueueJob on QueueJob {
  static final Set<String> _registeredTypes = {};

  /// Automatically registers this job type when first instantiated.
  /// Call this in your job's constructor.
  void autoRegister() {
    final typeName = runtimeType.toString();
    if (!_registeredTypes.contains(typeName)) {
      QueueJobRegistry.register(typeName, (json) => fromJson(json));
      _registeredTypes.add(typeName);
    }
  }
}

/// Better approach: Base class that handles auto-registration automatically
abstract class AutoRegisteredQueueJob implements QueueJob {
  static final Set<String> _registeredTypes = {};

  /// Constructor that automatically registers the job type
  AutoRegisteredQueueJob() {
    _ensureRegistration();
  }

  /// Internal method to handle auto-registration
  void _ensureRegistration() {
    final typeName = runtimeType.toString();

    if (!_registeredTypes.contains(typeName)) {
      try {
        // Try to register using the registrar
        jobRegistrar.register((json) => fromJson(json));
        _registeredTypes.add(typeName);
      } catch (e) {
        // Fallback to direct registry registration
        QueueJobRegistry.autoRegister(this);
        _registeredTypes.add(typeName);
      }
    }
  }

  @override
  Future<void> handle();

  @override
  Map<String, dynamic> toJson();

  @override
  QueueJob fromJson(Map<String, dynamic> json);
}

/// Mixin for jobs that prefer manual registration control
mixin ManualRegisterQueueJob on QueueJob {
  /// Manually register this job type
  void registerManually() {
    QueueJobRegistry.autoRegister(this);
  }

  /// Check if this job type is already registered
  bool get isRegistered => QueueJobRegistry.isRegistered(runtimeType.toString());
}

/// Utility class for job registration helpers
class JobRegistrationUtils {
  /// Registers a job using the enhanced registrar
  static void registerJob<T extends QueueJob>(T Function(Map<String, dynamic>) factory) {
    jobRegistrar.register(factory);
  }

  /// Registers multiple jobs at once
  static void registerJobs(List<QueueJobRegistration> jobs) {
    jobRegistrar.registerAll(jobs);
  }

  /// Creates a registration entry for a job
  static QueueJobRegistration<T> createRegistration<T extends QueueJob>(
    String typeName,
    T Function(Map<String, dynamic>) factory,
  ) {
    return QueueJobRegistration<T>(typeName, factory);
  }

  /// Validates that all expected jobs are registered
  static bool validateRegistrations(List<String> expectedTypes) {
    bool allValid = true;

    for (final type in expectedTypes) {
      if (!QueueJobRegistry.isRegistered(type)) {
        print('❌ Missing registration for job type: $type');
        allValid = false;
      }
    }

    return allValid;
  }
}
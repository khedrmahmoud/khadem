import '../../contracts/queue/queue_job.dart';

typedef QueueJobFactory = QueueJob Function(Map<String, dynamic> json);

/// Enhanced job registry with better error handling and registration patterns
class QueueJobRegistry {
  static final Map<String, QueueJobFactory> _factories = {};
  static final Map<String, Type> _registeredTypes = {};
  static final Set<String> _autoRegistered = {};

  /// Registers a job factory with enhanced error handling
  static void register(String type, QueueJobFactory factory) {
    if (_factories.containsKey(type)) {
      throw QueueJobRegistrationException('Job type "$type" is already registered');
    }

    _factories[type] = factory;
    _registeredTypes[type] = factory({}).runtimeType; // Store the actual type
  }

  /// Registers a job using its type name automatically
  static void registerJob<T extends QueueJob>(T Function(Map<String, dynamic>) factory) {
    final typeName = T.toString();
    register(typeName, factory);
  }

  /// Auto-registers a job instance (for backward compatibility)
  static void autoRegister(QueueJob job) {
    final typeName = job.runtimeType.toString();

    if (_autoRegistered.contains(typeName)) {
      return; // Already registered
    }

    if (!_factories.containsKey(typeName)) {
      register(typeName, (json) => job.fromJson(json));
      _autoRegistered.add(typeName);
    }
  }

  /// Creates a job from JSON with better error handling
  static QueueJob fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    if (type == null) {
      throw QueueJobDeserializationException('Job type not specified in JSON');
    }

    final factory = _factories[type];
    if (factory == null) {
      final availableTypes = _factories.keys.join(', ');
      throw QueueJobDeserializationException(
        'No factory registered for job type: "$type". '
        'Available types: [$availableTypes]'
      );
    }

    try {
      return factory(json);
    } catch (e) {
      throw QueueJobDeserializationException(
        'Failed to create job of type "$type": $e',
      );
    }
  }

  /// Checks if a job type is registered
  static bool isRegistered(String type) => _factories.containsKey(type);

  /// Gets all registered job types
  static Set<String> getRegisteredTypes() => _factories.keys.toSet();

  /// Gets the actual Type for a registered job type name
  static Type? getJobType(String typeName) => _registeredTypes[typeName];

  /// Clears all registrations (useful for testing)
  static void clear() {
    _factories.clear();
    _registeredTypes.clear();
    _autoRegistered.clear();
  }

  /// Gets registration statistics
  static Map<String, int> getStats() => {
    'total_registered': _factories.length,
    'auto_registered': _autoRegistered.length,
    'manual_registered': _factories.length - _autoRegistered.length,
  };
}

/// Exception thrown when job registration fails
class QueueJobRegistrationException implements Exception {
  final String message;
  QueueJobRegistrationException(this.message);

  @override
  String toString() => 'QueueJobRegistrationException: $message';
}

/// Exception thrown when job deserialization fails
class QueueJobDeserializationException implements Exception {
  final String message;
  QueueJobDeserializationException(this.message);

  @override
  String toString() => 'QueueJobDeserializationException: $message';
}

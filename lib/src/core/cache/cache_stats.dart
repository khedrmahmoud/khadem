/// Common cache statistics interface and implementation for all cache drivers.
///
/// This provides a standardized way to track and report cache performance metrics
/// across different cache implementations (memory, file, Redis, etc.).
///
/// ## Usage
///
/// ```dart
/// // In a cache driver implementation
/// final stats = CacheStats();
/// stats.hits++;
///
/// // Get statistics
/// final hitRate = stats.hitRate;
/// final totalOperations = stats.totalOperations;
/// ```
class CacheStats {
  /// Number of cache hits (successful retrievals)
  int hits = 0;

  /// Number of cache misses (failed retrievals)
  int misses = 0;

  /// Number of cache writes/sets
  int sets = 0;

  /// Number of cache deletions
  int deletions = 0;

  /// Number of expired entries encountered
  int expirations = 0;

  /// Number of cache clears
  int clears = 0;

  /// Creates a new CacheStats instance with default values.
  CacheStats();

  /// Creates a CacheStats instance with specific values.
  CacheStats.withValues({
    this.hits = 0,
    this.misses = 0,
    this.sets = 0,
    this.deletions = 0,
    this.expirations = 0,
    this.clears = 0,
  });

  /// Calculates the cache hit rate as a percentage.
  ///
  /// Returns a value between 0.0 and 100.0.
  /// If there are no operations, returns 0.0.
  double get hitRate {
    final total = hits + misses;
    return total > 0 ? (hits / total) * 100.0 : 0.0;
  }

  /// Gets the total number of cache operations.
  ///
  /// This includes hits, misses, sets, deletions, and clears.
  int get totalOperations => hits + misses + sets + deletions + clears;

  /// Gets the total number of read operations (hits + misses).
  int get readOperations => hits + misses;

  /// Gets the total number of write operations (sets + deletions + clears).
  int get writeOperations => sets + deletions + clears;

  /// Resets all statistics to zero.
  void reset() {
    hits = 0;
    misses = 0;
    sets = 0;
    deletions = 0;
    expirations = 0;
    clears = 0;
  }

  /// Creates a copy of this CacheStats instance.
  CacheStats copy() {
    return CacheStats.withValues(
      hits: hits,
      misses: misses,
      sets: sets,
      deletions: deletions,
      expirations: expirations,
      clears: clears,
    );
  }

  /// Converts the statistics to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'hits': hits,
      'misses': misses,
      'sets': sets,
      'deletions': deletions,
      'expirations': expirations,
      'clears': clears,
      'hit_rate': hitRate,
      'total_operations': totalOperations,
      'read_operations': readOperations,
      'write_operations': writeOperations,
    };
  }

  /// Creates a CacheStats instance from a JSON map.
  factory CacheStats.fromJson(Map<String, dynamic> json) {
    return CacheStats.withValues(
      hits: json['hits'] ?? 0,
      misses: json['misses'] ?? 0,
      sets: json['sets'] ?? 0,
      deletions: json['deletions'] ?? 0,
      expirations: json['expirations'] ?? 0,
      clears: json['clears'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'CacheStats('
        'hits: $hits, '
        'misses: $misses, '
        'sets: $sets, '
        'deletions: $deletions, '
        'expirations: $expirations, '
        'clears: $clears, '
        'hitRate: ${hitRate.toStringAsFixed(1)}%, '
        'totalOps: $totalOperations)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CacheStats) return false;
    return hits == other.hits &&
        misses == other.misses &&
        sets == other.sets &&
        deletions == other.deletions &&
        expirations == other.expirations &&
        clears == other.clears;
  }

  @override
  int get hashCode {
    return Object.hash(
      hits,
      misses,
      sets,
      deletions,
      expirations,
      clears,
    );
  }
}

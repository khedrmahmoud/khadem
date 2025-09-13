import 'package:khadem/src/core/cache/cache_stats.dart';

/// Interface for cache statistics management.
/// Defines the contract for tracking and reporting cache performance metrics.
abstract class ICacheStatisticsManager {
  /// Updates statistics for a cache operation.
  void updateStats(String driverName, {
    required bool hit,
    required String operation,
    bool error = false,
  });

  /// Gets statistics for a specific driver.
  CacheStats getStats(String driverName);

  /// Gets statistics for all drivers.
  Map<String, CacheStats> getAllStats();

  /// Resets statistics for a specific driver.
  void resetStats(String driverName);

  /// Resets statistics for all drivers.
  void resetAllStats();
}
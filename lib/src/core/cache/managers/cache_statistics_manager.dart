import 'package:khadem/src/core/cache/cache_stats.dart';

import '../../../contracts/cache/cache_statistics_manager.dart';

/// Implementation of cache statistics manager.
/// Manages cache performance metrics and statistics tracking.
class CacheStatisticsManager implements ICacheStatisticsManager {
  final Map<String, CacheStats> _stats = {};

  @override
  void updateStats(String driverName, {
    required bool hit,
    required String operation,
    bool error = false,
  }) {
    final currentStats = _getOrCreateStats(driverName);

    if (operation == 'get' || operation == 'has') {
      if (hit) {
        currentStats.hits++;
      } else {
        currentStats.misses++;
      }
    } else if (operation == 'put') {
      currentStats.sets++;
    } else if (operation == 'forget') {
      currentStats.deletions++;
    } else if (operation == 'clear') {
      currentStats.clears++;
    }

    // Note: CacheStats doesn't have an errors field, so we skip error tracking for now
    // This could be added to CacheStats if needed in the future
  }

  @override
  CacheStats getStats(String driverName) {
    return _getOrCreateStats(driverName).copy();
  }

  @override
  Map<String, CacheStats> getAllStats() {
    final result = <String, CacheStats>{};
    _stats.forEach((key, value) {
      result[key] = value.copy();
    });
    return result;
  }

  @override
  void resetStats(String driverName) {
    _stats[driverName] = CacheStats();
  }

  @override
  void resetAllStats() {
    _stats.clear();
  }

  /// Initializes statistics for a driver.
  void initializeDriverStats(String driverName) {
    if (!_stats.containsKey(driverName)) {
      _stats[driverName] = CacheStats();
    }
  }

  /// Gets or creates statistics for a driver.
  CacheStats _getOrCreateStats(String driverName) {
    return _stats.putIfAbsent(driverName, () => CacheStats());
  }
}
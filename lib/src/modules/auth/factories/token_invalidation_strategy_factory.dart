import '../contracts/token_invalidation_strategy.dart';
import '../contracts/token_service.dart';
import '../strategies/logout_strategies.dart';

/// Types of logout strategies available
enum LogoutType {
  singleDevice,
  allDevices,
}

/// Factory for creating token invalidation strategies
///
/// This factory follows the Factory pattern to create appropriate
/// logout strategies. Simplified to only include necessary strategies.
class TokenInvalidationStrategyFactory {
  final TokenService _tokenService;

  TokenInvalidationStrategyFactory(this._tokenService);

  /// Creates a strategy based on the logout type
  ///
  /// [logoutType] The type of logout strategy needed
  /// Returns the appropriate strategy instance
  TokenInvalidationStrategy createStrategy(LogoutType logoutType) {
    switch (logoutType) {
      case LogoutType.singleDevice:
        return SingleDeviceLogoutStrategy(_tokenService);
      case LogoutType.allDevices:
        return AllDevicesLogoutStrategy(_tokenService);
    }
  }

  /// Gets all available logout strategies
  ///
  /// Returns a map of logout types to their descriptions
  Map<LogoutType, String> getAvailableStrategies() {
    return {
      for (final type in LogoutType.values)
        type: createStrategy(type).description,
    };
  }
}
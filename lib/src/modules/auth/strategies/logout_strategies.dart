import '../contracts/token_invalidation_strategy.dart';
import '../contracts/token_service.dart';

/// Single device logout strategy
///
/// This strategy invalidates the current session/device tokens.
/// For JWT: Blacklists access token and removes associated refresh token
/// For Token: Simply deletes the access token
class SingleDeviceLogoutStrategy implements TokenInvalidationStrategy {
  final TokenService _tokenService;

  SingleDeviceLogoutStrategy(this._tokenService);

  @override
  String get description => 'Logout from current device only';

  @override
  Future<void> invalidateTokens(TokenInvalidationContext context) async {
    // For stateless tokens (JWT), blacklist the access token
    if (context.accessToken != null && context.tokenExpiry != null) {
      final blacklistData = {
        'token': context.accessToken!,
        'tokenable_id': context.userId,
        'guard': context.guard,
        'type': 'blacklist',
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.fromMillisecondsSinceEpoch(
          context.tokenExpiry! * 1000,
        ).toIso8601String(),
      };
      await _tokenService.blacklistToken(blacklistData);

      // For JWT, find and remove the associated refresh token using session correlation
      final sessionId = context.metadata?['session_id'] as String?;
      if (sessionId != null) {
        // Use session ID to find the exact refresh token for this session
        final sessionTokens = await _tokenService.findTokensBySession(
          sessionId,
          context.guard,
          'refresh',
        );

        // Remove the refresh token for this specific session
        for (final tokenData in sessionTokens) {
          final token = tokenData['token'] as String?;
          if (token != null) {
            await _tokenService.deleteToken(token);
          }
        }
      } 
      // Fallback: If no session ID, use the provided refresh token
      else if (context.refreshToken != null) {
        await _tokenService.deleteToken(context.refreshToken!);
      }
    }
    
    // For stateful tokens, simply delete the access token
    else if (context.accessToken != null) {
      await _tokenService.deleteToken(context.accessToken!);
    }
  }
}

/// All devices logout strategy
///
/// This strategy invalidates all tokens for a user across all devices.
/// Works for both JWT and Token drivers.
class AllDevicesLogoutStrategy implements TokenInvalidationStrategy {
  final TokenService _tokenService;

  AllDevicesLogoutStrategy(this._tokenService);

  @override
  String get description => 'Logout from all devices';

  @override
  Future<void> invalidateTokens(TokenInvalidationContext context) async {
    // Blacklist/delete the current access token
    if (context.accessToken != null && context.tokenExpiry != null) {
      // JWT tokens - blacklist the access token
      final blacklistData = {
        'token': context.accessToken!,
        'tokenable_id': context.userId,
        'guard': context.guard,
        'type': 'blacklist',
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.fromMillisecondsSinceEpoch(
          context.tokenExpiry! * 1000,
        ).toIso8601String(),
      };
      await _tokenService.blacklistToken(blacklistData);
    } else if (context.accessToken != null) {
      // Stateful tokens - delete the access token
      await _tokenService.deleteToken(context.accessToken!);
    }

    // Delete ALL tokens for this user (complete logout from all devices)
    final userTokens = await _tokenService.findTokensByUser(
      context.userId,
      context.guard,
    );

    for (final tokenData in userTokens) {
      final tokenType = tokenData['type'] as String?;
      // Remove all refresh tokens and access tokens (but not blacklist entries)
      if (tokenType == 'refresh' || tokenType == 'access') {
        final token = tokenData['token'] as String;
        await _tokenService.deleteToken(token);
      }
    }
  }
}
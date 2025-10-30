import 'dart:io';

/// Session Cookie Handler
/// Handles HTTP cookie operations for sessions
class SessionCookieHandler {
  static const String defaultCookieName = 'khadem_session';

  final String cookieName;
  final Duration defaultMaxAge;
  final bool secure;
  final bool httpOnly;
  final String sameSite;
  final String? domain;

  SessionCookieHandler({
    this.cookieName = defaultCookieName,
    this.defaultMaxAge = const Duration(hours: 24),
    this.secure = false,
    this.httpOnly = true,
    this.sameSite = 'lax',
    this.domain,
  });

  /// Extract session ID from request cookies
  String? getSessionIdFromRequest(HttpRequest request) {
    try {
      final cookie = request.cookies.firstWhere(
        (cookie) => cookie.name == cookieName,
      );
      return cookie.value;
    } catch (e) {
      return null;
    }
  }

  /// Set session cookie in response
  void setSessionCookie(
    HttpResponse response,
    String sessionId, {
    Duration? maxAge,
  }) {
    final cookie = Cookie(cookieName, sessionId);
    cookie.maxAge = (maxAge ?? defaultMaxAge).inSeconds;
    cookie.httpOnly = httpOnly;
    cookie.secure = secure;
    cookie.path = '/';
    if (domain != null) {
      cookie.domain = domain;
    }

    switch (sameSite.toLowerCase()) {
      case 'strict':
        cookie.sameSite = SameSite.strict;
        break;
      case 'lax':
        cookie.sameSite = SameSite.lax;
        break;
      default:
        // Keep default
        break;
    }

    response.cookies.add(cookie);
  }

  /// Clear session cookie
  void clearSessionCookie(HttpResponse response) {
    final cookie = Cookie(cookieName, '');
    cookie.maxAge = 0;
    cookie.expires = DateTime.now().subtract(const Duration(seconds: 1));
    cookie.path = '/';
    if (domain != null) {
      cookie.domain = domain;
    }
    response.cookies.add(cookie);
  }
}

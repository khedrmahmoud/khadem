import 'dart:convert';
import 'dart:io';

/// Cookie Manager
///
/// A clean and solid cookie management system that provides a unified interface
/// for handling HTTP cookies in requests and responses.
class CookieManager {
  /// Gets a cookie value from the request
  static String? getCookie(HttpRequest request, String name) {
    for (final cookie in request.cookies) {
      if (cookie.name == name) return cookie.value;
    }
    return null;
  }

  /// Gets all cookies from the request as a map
  static Map<String, String> getAllCookies(HttpRequest request) {
    return Map.fromEntries(
      request.cookies.map((cookie) => MapEntry(cookie.name, cookie.value)),
    );
  }

  /// Sets a cookie in the response
  static void setCookie(
    HttpResponse response,
    String name,
    String value, {
    String? domain,
    String? path = '/',
    DateTime? expires,
    Duration? maxAge,
    bool httpOnly = false,
    bool secure = false,
    String? sameSite,
  }) {
    final cookie = Cookie(name, value);

    if (domain != null) cookie.domain = domain;
    if (path != null) cookie.path = path;
    if (expires != null) cookie.expires = expires;
    if (maxAge != null) cookie.maxAge = maxAge.inSeconds;
    cookie.httpOnly = httpOnly;
    cookie.secure = secure;

    if (sameSite != null) {
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
    }

    response.cookies.add(cookie);
  }

  /// Sets multiple cookies at once
  static void setCookies(
    HttpResponse response,
    Map<String, String> cookies, {
    String? domain,
    String? path = '/',
    DateTime? expires,
    Duration? maxAge,
    bool httpOnly = false,
    bool secure = false,
    String? sameSite,
  }) {
    for (final entry in cookies.entries) {
      setCookie(
        response,
        entry.key,
        entry.value,
        domain: domain,
        path: path,
        expires: expires,
        maxAge: maxAge,
        httpOnly: httpOnly,
        secure: secure,
        sameSite: sameSite,
      );
    }
  }

  /// Deletes a cookie by setting it to expire immediately
  static void deleteCookie(
    HttpResponse response,
    String name, {
    String? domain,
    String? path = '/',
  }) {
    setCookie(
      response,
      name,
      '',
      maxAge: Duration.zero,
      expires: DateTime.now().subtract(const Duration(seconds: 1)),
      domain: domain,
      path: path,
    );
  }

  /// Deletes multiple cookies at once
  static void deleteCookies(
    HttpResponse response,
    List<String> names, {
    String? domain,
    String? path = '/',
  }) {
    for (final name in names) {
      deleteCookie(response, name, domain: domain, path: path);
    }
  }

  /// Creates a remember token cookie (for "remember me" functionality)
  static void setRememberToken(
    HttpResponse response,
    String token, {
    Duration maxAge = const Duration(days: 30),
    bool secure = false,
    bool httpOnly = true,
  }) {
    setCookie(
      response,
      'remember_token',
      token,
      maxAge: maxAge,
      httpOnly: httpOnly,
      secure: secure,
      sameSite: 'lax',
    );
  }

  /// Gets the remember token from request
  static String? getRememberToken(HttpRequest request) {
    return getCookie(request, 'remember_token');
  }

  /// Clears the remember token cookie
  static void clearRememberToken(HttpResponse response) {
    deleteCookie(response, 'remember_token');
  }

  /// Creates a flash message cookie
  static void setFlashMessage(
    HttpResponse response,
    String type,
    String message, {
    bool secure = false,
  }) {
    final flashData = {'type': type, 'message': message};
    setCookie(
      response,
      'flash_message',
      jsonEncode(flashData),
      maxAge: const Duration(seconds: 30), // Short-lived
      secure: secure,
      sameSite: 'lax',
    );
  }

  /// Gets flash message from request and clears it
  static Map<String, String>? getFlashMessage(
    HttpRequest request,
    HttpResponse response,
  ) {
    final flashCookie = getCookie(request, 'flash_message');
    if (flashCookie == null) return null;

    // Clear the flash cookie
    deleteCookie(response, 'flash_message');

    try {
      final decoded = jsonDecode(flashCookie) as Map<String, dynamic>;
      return {
        'type': decoded['type'] as String,
        'message': decoded['message'] as String,
      };
    } catch (e) {
      // Invalid flash data
      return null;
    }
  }
}

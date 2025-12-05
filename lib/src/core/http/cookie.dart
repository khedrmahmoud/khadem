import 'dart:convert';
import 'dart:io';

/// Cookies Manager
///
/// A clean and solid cookie management system that provides a unified interface
/// for handling HTTP cookies in requests and responses.
class Cookies {
  final HttpRequest? _request;
  final HttpResponse? _response;

  /// Creates a Cookies instance for a request (read-only).
  Cookies(this._request) : _response = null;

  /// Creates a Cookies instance for a response (write-only).
  Cookies.response(this._response) : _request = null;

  /// Creates a Cookies instance for both request and response.
  Cookies.context(this._request, this._response);

  // ==========================================
  // Request Methods (Read)
  // ==========================================

  /// Gets a cookie value from the request.
  String? get(String name) {
    if (_request == null) return null;
    for (final cookie in _request!.cookies) {
      if (cookie.name == name) return cookie.value;
    }
    return null;
  }

  /// Gets a cookie object from the request.
  Cookie? getCookie(String name) {
    if (_request == null) return null;
    for (final cookie in _request!.cookies) {
      if (cookie.name == name) return cookie;
    }
    return null;
  }

  /// Gets all cookies from the request as a map.
  Map<String, String> get all {
    if (_request == null) return {};
    return Map.fromEntries(
      _request!.cookies.map((cookie) => MapEntry(cookie.name, cookie.value)),
    );
  }

  /// Checks if a cookie exists in the request.
  bool has(String name) {
    if (_request == null) return false;
    for (final cookie in _request!.cookies) {
      if (cookie.name == name) return true;
    }
    return false;
  }

  // ==========================================
  // Response Methods (Write)
  // ==========================================

  /// Sets a cookie in the response.
  void set(
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
    if (_response == null) return;
    
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

    _response!.cookies.add(cookie);
  }

  /// Sets multiple cookies at once.
  void setAll(
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
      set(
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

  /// Deletes a cookie by setting it to expire immediately.
  void delete(
    String name, {
    String? domain,
    String? path = '/',
  }) {
    set(
      name,
      '',
      maxAge: Duration.zero,
      expires: DateTime.now().subtract(const Duration(seconds: 1)),
      domain: domain,
      path: path,
    );
  }

  /// Deletes multiple cookies at once.
  void deleteAll(
    List<String> names, {
    String? domain,
    String? path = '/',
  }) {
    for (final name in names) {
      delete(name, domain: domain, path: path);
    }
  }

  // ==========================================
  // Special Cookies
  // ==========================================

  /// Gets the CSRF token cookie.
  String? get csrfToken => get('csrf_token');

  /// Gets the remember token cookie.
  String? get rememberToken => get('remember_token');

  /// Sets the remember token cookie.
  void setRememberToken(
    String token, {
    Duration maxAge = const Duration(days: 30),
    bool secure = false,
    bool httpOnly = true,
  }) {
    set(
      'remember_token',
      token,
      maxAge: maxAge,
      httpOnly: httpOnly,
      secure: secure,
      sameSite: 'lax',
    );
  }

  /// Clears the remember token cookie.
  void clearRememberToken() {
    delete('remember_token');
  }

  /// Sets a flash message cookie.
  void setFlashMessage(
    String type,
    String message, {
    bool secure = false,
  }) {
    final flashData = {'type': type, 'message': message};
    set(
      'flash_message',
      jsonEncode(flashData),
      maxAge: const Duration(seconds: 30), // Short-lived
      secure: secure,
      sameSite: 'lax',
    );
  }

  /// Gets flash message from request and clears it (if response is available).
  Map<String, String>? getFlashMessage() {
    final flashCookie = get('flash_message');
    if (flashCookie == null) return null;

    // Clear the flash cookie if we can write to response
    if (_response != null) {
      delete('flash_message');
    }

    try {
      final decoded = jsonDecode(flashCookie) as Map<String, dynamic>;
      return {
        'type': decoded['type'] as String,
        'message': decoded['message'] as String,
      };
    } catch (e) {
      return null;
    }
  }
}

/// Static helper for backward compatibility or direct usage
class CookieManager {
  static String? getCookie(HttpRequest request, String name) => Cookies(request).get(name);
  static Map<String, String> getAllCookies(HttpRequest request) => Cookies(request).all;
  static void setCookie(HttpResponse response, String name, String value, {String? domain, String? path, DateTime? expires, Duration? maxAge, bool httpOnly = false, bool secure = false, String? sameSite}) => Cookies.response(response).set(name, value, domain: domain, path: path, expires: expires, maxAge: maxAge, httpOnly: httpOnly, secure: secure, sameSite: sameSite);
  static void deleteCookie(HttpResponse response, String name, {String? domain, String? path}) => Cookies.response(response).delete(name, domain: domain, path: path);
}

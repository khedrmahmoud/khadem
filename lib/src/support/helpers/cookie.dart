import 'dart:io';

import 'package:khadem/src/core/http/cookie.dart' show CookieManager;

/// Cookie Helper class for convenient cookie access
class CookieHelper {
  final HttpRequest? _request;
  final HttpResponse? _response;

  CookieHelper(HttpRequest? request)
      : _request = request,
        _response = null;
  CookieHelper.response(HttpResponse? response)
      : _request = null,
        _response = response;

  /// Gets a cookie value
  String? get(String name) {
    if (_request == null) return null;
    for (final cookie in _request!.cookies) {
      if (cookie.name == name) return cookie.value;
    }
    return null;
  }

  /// Gets a cookie object
  Cookie? getCookie(String name) {
    if (_request == null) return null;
    for (final cookie in _request!.cookies) {
      if (cookie.name == name) return cookie;
    }
    return null;
  }

  /// Gets all cookies as a map
  Map<String, String> get all {
    if (_request == null) return {};
    return Map.fromEntries(
      _request!.cookies.map((cookie) => MapEntry(cookie.name, cookie.value)),
    );
  }

  /// Checks if a cookie exists
  bool has(String name) {
    if (_request == null) return false;
    for (final cookie in _request!.cookies) {
      if (cookie.name == name) return true;
    }
    return false;
  }

  /// Sets a cookie
  void set(
    String name,
    String value, {
    String? domain,
    String? path,
    DateTime? expires,
    Duration? maxAge,
    bool httpOnly = false,
    bool secure = false,
    String? sameSite,
  }) {
    if (_response == null) return;
    CookieManager.setCookie(
      _response!,
      name,
      value,
      domain: domain,
      path: path,
      expires: expires,
      maxAge: maxAge,
      httpOnly: httpOnly,
      secure: secure,
      sameSite: sameSite,
    );
  }

  /// Sets multiple cookies
  void setAll(
    Map<String, String> cookies, {
    String? domain,
    String? path,
    DateTime? expires,
    Duration? maxAge,
    bool httpOnly = false,
    bool secure = false,
    String? sameSite,
  }) {
    if (_response == null) return;
    CookieManager.setCookies(
      _response!,
      cookies,
      domain: domain,
      path: path,
      expires: expires,
      maxAge: maxAge,
      httpOnly: httpOnly,
      secure: secure,
      sameSite: sameSite,
    );
  }

  /// Deletes a cookie
  void delete(String name, {String? domain, String? path}) {
    if (_response == null) return;
    CookieManager.deleteCookie(_response!, name, domain: domain, path: path);
  }

  /// Deletes multiple cookies
  void deleteAll(List<String> names, {String? domain, String? path}) {
    if (_response == null) return;
    CookieManager.deleteCookies(_response!, names, domain: domain, path: path);
  }

  /// Sets a remember token
  void setRememberToken(
    String token, {
    Duration maxAge = const Duration(days: 30),
    bool secure = false,
    bool httpOnly = true,
  }) {
    if (_response == null) return;
    CookieManager.setRememberToken(
      _response!,
      token,
      maxAge: maxAge,
      secure: secure,
      httpOnly: httpOnly,
    );
  }

  /// Gets the remember token
  String? get rememberToken {
    if (_request == null) return null;
    for (final cookie in _request!.cookies) {
      if (cookie.name == 'remember_token') return cookie.value;
    }
    return null;
  }

  /// Clears the remember token
  void clearRememberToken() {
    if (_response == null) return;
    CookieManager.clearRememberToken(_response!);
  }

  /// Sets a flash message
  void setFlashMessage(String type, String message, {bool secure = false}) {
    if (_response == null) return;
    CookieManager.setFlashMessage(_response!, type, message, secure: secure);
  }

  /// Gets and clears flash message
  Map<String, String>? get flashMessage {
    if (_request == null || _response == null) return null;
    return CookieManager.getFlashMessage(_request!, _response!);
  }
}

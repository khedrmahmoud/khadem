import 'dart:io';

class CookieHelper {
  static Cookie? getCookie(HttpRequest req, String name) {
    return req.cookies.firstWhere((cookie) => cookie.name == name);
  }

  static void setCookie(HttpResponse res, String name, String value,
      {int maxAge = 3600,
      String path = '/',
      bool httpOnly = true,
      bool secure = false,}) {
    final cookie = Cookie(name, value)
      ..maxAge = maxAge
      ..path = path
      ..httpOnly = httpOnly
      ..secure = secure;

    res.cookies.add(cookie);
  }

  static void deleteCookie(HttpResponse res, String name) {
    final expired = Cookie(name, '')
      ..maxAge = 0
      ..expires = DateTime.now().subtract(const Duration(days: 1));
    res.cookies.add(expired);
  }
}

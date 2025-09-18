import 'dart:async';

import 'package:khadem/khadem_dart.dart'
    show Middleware, NextFunction, Request, Response, CookieHelper;

import '../../core/http/session.dart';

/// Session Middleware
///
/// Automatically manages session lifecycle for HTTP requests.
/// Creates, retrieves, and manages session data throughout the request lifecycle.
class SessionMiddleware extends Middleware {
  final SessionManager _sessionManager;

  SessionMiddleware({
    SessionManager? sessionManager,
  })  : _sessionManager = sessionManager ?? SessionManager(),
        super(_handleSession);

  /// Handles session management for the request
  static FutureOr<void> _handleSession(
    Request req,
    Response res,
    NextFunction next,
  ) async {
    final middleware = SessionMiddleware();
    await middleware._processSession(req, res, next);
  }

  /// Processes session for the current request
  Future<void> _processSession(
    Request req,
    Response res,
    NextFunction next,
  ) async {
    String? sessionId;

    try {
      // Try to get existing session ID from cookie
      sessionId = _sessionManager.getSessionIdFromRequest(req.raw);

      Map<String, dynamic> sessionData;

      if (sessionId != null) {
        // Load existing session
        sessionData = await _sessionManager.getSession(sessionId) ?? {};
      } else {
        // Create new session
        sessionId = await _sessionManager.createSession();
        sessionData = {};
      }

      // Store session data in request
      req.setAttribute('session', sessionData);
      req.setAttribute('session_id', sessionId);
      // Retrieve and clear flashed old input
      final oldInput = await _sessionManager.getOldInput(sessionId);
      if (oldInput != null) {
        req.setAttribute('old', oldInput);
      }

      // Continue to next middleware/route handler
      await next();

      // After request processing, save session data
      final updatedSession = req.params.attribute('session');
      if (updatedSession is Map<String, dynamic>) {
        await _sessionManager.updateSession(sessionId, updatedSession);
      }

      // Set session cookie in response
      _sessionManager.setSessionCookie(res.raw.response, sessionId);
    } catch (e) {
      // If session handling fails, continue without session
      await next();
    }
  }

  /// Gets the current session manager instance
  SessionManager get sessionManager => _sessionManager;
}

/// Cookie Middleware
///
/// Provides convenient cookie access methods to requests and responses.
/// Adds cookie helper methods to the request and response objects.
class CookieMiddleware extends Middleware {
  CookieMiddleware() : super(_handleCookies);

  /// Handles cookie management for the request
  static FutureOr<void> _handleCookies(
    Request req,
    Response res,
    NextFunction next,
  ) async {
    // Add cookie helper methods to request
    req.setAttribute('cookies', CookieHelper(req.raw));

    // Add cookie helper methods to request (we'll access response through the helper)
    req.setAttribute(
        'response_cookies', CookieHelper.response(res.raw.response),);

    // Continue to next middleware/route handler
    await next();
  }
}

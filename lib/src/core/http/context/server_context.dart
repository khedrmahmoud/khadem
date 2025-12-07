import 'dart:async';

import '../../../support/exceptions/missing_server_context_exception.dart';
import '../../routing/route_match_result.dart';

import '../request/request.dart';
import '../response/response.dart';

/// Holds the matched route and request/response pair for processing.
///
/// This class serves as the central context for HTTP request processing,
/// containing all the information needed to handle a request from routing
/// to response generation.
///
/// Key features:
/// - Route matching and parameter extraction
/// - Request/response lifecycle management
/// - Middleware execution context
/// - Request timing and profiling
class ServerContext {
  static const _zoneKey = #serverContext;
  static Symbol get zoneKey => _zoneKey;

  final Request request;
  final Response? response;
  
  RouteMatchResult? _matchedRoute;

  /// Timestamp when the request started processing
  final DateTime _startTime = DateTime.now();

  /// Custom data storage for this request
  final Map<String, dynamic> _data = {};

  ServerContext({
    required this.request,
    this.response,
  });

  /// Get the current server context from the zone.
  static ServerContext get current {
    final context = Zone.current[_zoneKey] as ServerContext?;
    if (context == null) {
      throw MissingServerContextException();
    }
    return context;
  }

  /// Check if a server context is currently available.
  static bool get hasContext => Zone.current[_zoneKey] != null;

  /// Whether a route has been matched for this request
  bool get hasMatch => _matchedRoute != null;

  /// Get the matched route result for the current request
  RouteMatchResult? get matchedRoute => _matchedRoute;

  /// Set the matched route for this context
  void setMatch(RouteMatchResult match) {
    _matchedRoute = match;
  }

  /// Duration since the request started processing
  Duration get processingTime => DateTime.now().difference(_startTime);

  /// Store custom data for this request context
  void setData(String key, dynamic value) {
    _data[key] = value;
  }

  /// Retrieve custom data from this request context
  T? getData<T>(String key) {
    return _data[key] as T?;
  }

  /// Check if custom data exists
  bool hasData(String key) => _data.containsKey(key);

  /// Remove custom data
  void removeData(String key) => _data.remove(key);

  /// Clear all custom data
  void clearData() => _data.clear();

  /// Get all custom data
  Map<String, dynamic> get allData => Map.unmodifiable(_data);
}

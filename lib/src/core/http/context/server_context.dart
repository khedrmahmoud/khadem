import 'dart:async';

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
  final Response response;
  final RouteMatchResult? Function(String method, String path)? match;

  /// Timestamp when the request started processing
  final DateTime _startTime = DateTime.now();

  /// Custom data storage for this request
  final Map<String, dynamic> _data = {};

  ServerContext({
    required this.request,
    required this.response,
    required this.match,
  });

  /// Whether a route has been matched for this request
  bool get hasMatch => match != null;

  /// Get the matched route result for the current request
  RouteMatchResult? get matchedRoute {
    if (match == null) return null;
    return match!(request.method, request.path);
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

  /// Execute a function within this server context
  R run<R>(R Function() body) {
    return runZoned(
      () {
        final result = body();
        // Log processing time if it took more than 100ms
        final duration = processingTime;
        if (duration.inMilliseconds > 100) {
          // Could integrate with logger here
          print(
            '[ServerContext] Request processed in ${duration.inMilliseconds}ms',
          );
        }
        return result;
      },
      zoneValues: {zoneKey: this},
    );
  }
}

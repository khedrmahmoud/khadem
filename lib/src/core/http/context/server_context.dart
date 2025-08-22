import '../../routing/route_match_result.dart';

import '../request/request.dart';
import '../response/response.dart';

/// Holds the matched route and request/response pair for processing.
class ServerContext {
  static final _zoneKey = #serverContext;
  static Symbol get zoneKey => _zoneKey;

  final Request request;
  final Response response;
  final RouteMatchResult? Function(String method, String path)? match;

  ServerContext({
    required this.request,
    required this.response,
    required this.match,
  });

  bool get hasMatch => match != null;
}

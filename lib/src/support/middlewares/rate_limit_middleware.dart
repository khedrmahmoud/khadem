import '../../contracts/http/middleware_contract.dart';

/// A middleware that limits the number of requests from a single IP address
/// within a specified time window.
class RateLimitMiddleware implements Middleware {
  final int maxRequests;
  final Duration window;
  final _RateLimitStore _store;

  RateLimitMiddleware({
    this.maxRequests = 60,
    this.window = const Duration(minutes: 1),
  }) : _store = _RateLimitStore(window);

  @override
  MiddlewareHandler get handler => (req, res, next) async {
        final ip = req.ip;

        if (_store.isRateLimited(ip, maxRequests)) {
          res.status(429).sendJson({
            'error': 'Too Many Requests',
            'message': 'You have exceeded the rate limit.',
            'retry_after': _store.getRetryAfter(ip).inSeconds,
          });
          return;
        }

        _store.increment(ip);

        // Add rate limit headers
        final remaining = maxRequests - _store.getRequestCount(ip);
        final reset = _store.getResetTime(ip).millisecondsSinceEpoch ~/ 1000;

        res.header('X-RateLimit-Limit', maxRequests.toString());
        res.header('X-RateLimit-Remaining', remaining.toString());
        res.header('X-RateLimit-Reset', reset.toString());

        await next();
      };

  @override
  String get name => "RateLimit";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.global;
}

class _RateLimitStore {
  final Duration window;
  final Map<String, List<DateTime>> _requests = {};

  // Cleanup timer
  DateTime _lastCleanup = DateTime.now();

  _RateLimitStore(this.window);

  bool isRateLimited(String ip, int maxRequests) {
    _cleanupIfNeeded();

    if (!_requests.containsKey(ip)) {
      return false;
    }

    final now = DateTime.now();
    final windowStart = now.subtract(window);

    // Filter out old requests
    _requests[ip] =
        _requests[ip]!.where((time) => time.isAfter(windowStart)).toList();

    return _requests[ip]!.length >= maxRequests;
  }

  void increment(String ip) {
    if (!_requests.containsKey(ip)) {
      _requests[ip] = [];
    }
    _requests[ip]!.add(DateTime.now());
  }

  int getRequestCount(String ip) {
    if (!_requests.containsKey(ip)) return 0;
    return _requests[ip]!.length;
  }

  DateTime getResetTime(String ip) {
    if (!_requests.containsKey(ip) || _requests[ip]!.isEmpty) {
      return DateTime.now().add(window);
    }
    // The window resets when the oldest request expires
    return _requests[ip]!.first.add(window);
  }

  Duration getRetryAfter(String ip) {
    final resetTime = getResetTime(ip);
    return resetTime.difference(DateTime.now());
  }

  void _cleanupIfNeeded() {
    final now = DateTime.now();
    // Run cleanup every minute
    if (now.difference(_lastCleanup).inMinutes >= 1) {
      final windowStart = now.subtract(window);
      _requests.removeWhere((key, times) {
        final validTimes =
            times.where((time) => time.isAfter(windowStart)).toList();
        if (validTimes.isEmpty) return true;
        _requests[key] = validTimes;
        return false;
      });
      _lastCleanup = now;
    }
  }
}

import '../../contracts/http/middleware_contract.dart';
import '../../core/http/request/request.dart';
import '../../core/http/response/response.dart';
import '../../core/http/response/response_wrapper.dart';

class CacheMiddleware implements Middleware {
  final _memoryCache = <String, Map<String, dynamic>>{};
  final Duration duration;

  CacheMiddleware({this.duration = const Duration(seconds: 10)});

  Future<void> handle(Request req, Response res, NextFunction next) async {
    if (req.method != 'GET') return next();

    final key = req.uri.toString();
    if (_memoryCache.containsKey(key)) {
      res.sendJson(_memoryCache[key]!);
      return;
    }

    final capturedRes = ResponseWrapper(req.raw);
    await next();

    if (capturedRes.sent && capturedRes.data != null) {
      _memoryCache[key] = capturedRes.data!;
      Future.delayed(duration, () => _memoryCache.remove(key));
    }
  }

  @override
  MiddlewareHandler get handler => handle;
  @override
  String get name => "MemoryCache";

  @override
  MiddlewarePriority get priority => MiddlewarePriority.terminating;
}

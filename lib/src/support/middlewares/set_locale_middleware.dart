import '../../contracts/http/middleware_contract.dart';
import '../../contracts/http/response_contract.dart';
import '../../core/http/request/request.dart';
import '../../core/lang/lang.dart';

class SetLocaleMiddleware implements Middleware {
  @override
  MiddlewareHandler get handler =>
      (Request req, ResponseContract res, NextFunction next) async {
        try {
          final lang = req.headers.get('accept-language');
          if (lang == null) return await next();
          Lang.setRequestLocale(lang);
          await next();
        } catch (e) {
          await next();
        }
      };

  @override
  String get name => 'SetLocale';

  @override
  MiddlewarePriority get priority => MiddlewarePriority.business;
}

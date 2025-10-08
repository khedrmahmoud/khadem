import 'package:khadem/src/contracts/views/directive_contract.dart';
import 'package:khadem/src/core/http/context/request_context.dart';
/// Auth directive
/// Renders content between @auth and @endauth if user is authenticated
class AuthDirective implements ViewDirective {
  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    final authenticated = RequestContext.isAuthenticated;
    final pattern = RegExp(r'@auth([\s\S]*?)@endauth');
    return content.replaceAllMapped(pattern, (match) {
      return authenticated ? match.group(1)! : '';
    });
  }
}

/// Guest directive
/// Renders content between @guest and @endguest if user is not authenticated
class GuestDirective implements ViewDirective {
  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    final authenticated = RequestContext.isAuthenticated;
    final pattern = RegExp(r'@guest([\s\S]*?)@endguest');
    return content.replaceAllMapped(pattern, (match) {
      return !authenticated ? match.group(1)! : '';
    });
  }
}

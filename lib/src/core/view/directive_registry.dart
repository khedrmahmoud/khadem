import 'package:khadem/khadem_dart.dart';

import 'directives/include_directive.dart';
import 'directives/for_directive.dart';
import 'directives/if_directive.dart';
import 'directives/layout_directive.dart';
import 'directives/lang_directive.dart';

class DirectiveRegistry {
  static final List<ViewDirective> _directives = [
    IncludeDirective(),
    ForDirective(),
    IfDirective(),
    LayoutDirective(),
    LangDirective(),
  ];

  static void register(ViewDirective directive) {
    _directives.add(directive);
  }

  static Future<String> applyAll(
      String content, Map<String, dynamic> context) async {
    for (final directive in _directives) {
      content = await directive.apply(content, context);
    }
    return content;
  }
}

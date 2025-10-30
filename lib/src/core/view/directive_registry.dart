import 'package:khadem/src/application/khadem.dart';
import 'package:khadem/src/contracts/views/directive_contract.dart';

import 'directives/array_directives.dart';
import 'directives/asset_directives.dart';
import 'directives/auth_directives.dart';
import 'directives/control_flow_directives.dart';
import 'directives/data_directives.dart';
import 'directives/for_directive.dart';
import 'directives/form_directives.dart';
import 'directives/if_directive.dart';
import 'directives/include_directive.dart';
import 'directives/lang_directive.dart';
import 'directives/layout_directive.dart';
import 'directives/loop_directives.dart';
import 'directives/output_directives.dart';
import 'directives/section_directive.dart';
import 'directives/string_directives.dart';
import 'directives/utility_directives.dart';

class DirectiveRegistry {
  static final List<ViewDirective> _directives = [
    // Original directives
    IncludeDirective(),
    ForDirective(),
    IfDirective(),
    LayoutDirective(),
    LangDirective(),
    SectionDirective(),

    // Control flow directives
    UnlessDirective(),
    ElseIfDirective(),
    ElseDirective(),
    SwitchDirective(),

    // Loop directives
    ForeachDirective(),
    WhileDirective(),
    BreakDirective(),
    ContinueDirective(),

    // Data manipulation directives
    SetDirective(),
    UnsetDirective(),
    PushDirective(),
    StackDirective(),

    // Output and debugging directives
    JsonDirective(),
    DumpDirective(),
    DdDirective(),
    CommentDirective(),

    // Asset directives
    AssetDirective(),
    CssDirective(),
    JsDirective(),
    InlineCssDirective(),
    InlineJsDirective(),
    UrlRouteDirective(),

    // Utility directives
    EnvDirective(),
    ConfigDirective(),
    NowDirective(),
    FormatDirective(),
    MathDirective(),

    // String directives
    StrtoupperDirective(),
    StrtolowerDirective(),
    StrlenDirective(),
    SubstrDirective(),
    ReplaceDirective(),

    // Array directives
    CountDirective(),
    EmptyDirective(),
    IssetDirective(),
    HasDirective(),

    // Form directives
    CsrfDirective(),
    MethodDirective(),
    RouteDirective(),
    UrlDirective(),
    ActionDirective(),
    OldDirective(),
    // Auth/Guest directives
    AuthDirective(),
    GuestDirective(),
  ];

  static void register(ViewDirective directive) {
    _directives.add(directive);
  }

  static Future<String> applyAll(
    String content,
    Map<String, dynamic> context,
  ) async {
    for (final directive in _directives) {
      try {
        content = await directive.apply(content, context);
      } catch (e) {
        // Log error but continue processing other directives
        Khadem.logger
            .error('Error applying directive ${directive.runtimeType}: $e');
      }
    }
    return content;
  }
}

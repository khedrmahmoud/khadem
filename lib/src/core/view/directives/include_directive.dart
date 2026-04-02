import 'dart:io';

import 'package:khadem/src/contracts/views/directive_contract.dart';
import '../../../support/utils/path_validator.dart';

class IncludeDirective implements ViewDirective {
  static final _includeRegex = RegExp(r"""@include\(['\"](.*?)['\"]\)""");
  static const _viewsBasePath = 'resources/views';
  static final _pathValidator = PathValidator(_viewsBasePath);

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_includeRegex, (match) {
      final includeFile = match.group(1)!;
      final filePath = '$includeFile.khdm.html';

      // Validate and resolve the path (throws SecurityException if invalid)
      final safePath = _pathValidator.validateAndResolve(
        filePath,
        context: 'include',
      );

      final file = File(safePath);
      if (!file.existsSync()) return '';
      return file.readAsStringSync();
    });
  }
}

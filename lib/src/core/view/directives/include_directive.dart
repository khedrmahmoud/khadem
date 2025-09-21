import 'dart:io';
import 'package:khadem/khadem.dart';
import 'package:path/path.dart' as p;

class IncludeDirective implements ViewDirective {
  static final _includeRegex = RegExp(r"""@include\(['\"](.*?)['\"]\)""");

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    return content.replaceAllMapped(_includeRegex, (match) {
      final includeFile = match.group(1)!;
      final path = p.join('resources/views', '$includeFile.khdm.html');
      final file = File(path);
      if (!file.existsSync()) return '';
      return file.readAsStringSync();
    });
  }
}

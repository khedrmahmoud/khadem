import 'package:khadem/khadem.dart';

class SectionDirective implements ViewDirective {
  final Map<String, String> sections = {};

  @override
  Future<String> apply(String content, Map<String, dynamic> context) async {
    extractSections(content);
    // Return content without sections
    return _removeSections(content);
  }

  Map<String, String> extractSections(String content) {
    final sectionRegex = RegExp(
      r"""@section\s*\(\s*['"](.+?)['"]\s*\)\s*([\s\S]+?)@endsection""",
    );

    sections.clear(); // clear old values

    for (final match in sectionRegex.allMatches(content)) {
      final name = match.group(1)!;
      final body = match.group(2)!.trim();
      sections[name] = body;
    }

    return sections;
  }

  String _removeSections(String content) {
    final sectionRegex = RegExp(
      r"""@section\s*\(\s*['"](.+?)['"]\s*\)\s*([\s\S]+?)@endsection""",
    );
    return content.replaceAll(sectionRegex, '');
  }
}

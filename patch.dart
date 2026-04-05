import 'dart:io';
void main() {
  final f = File('lib/src/core/validation/input_validator.dart');
  var s = f.readAsStringSync();
  s = s.replaceFirst(
      'List<String> _expandFieldPattern(String pattern) {',
      'List<String> _expandFieldPattern(String pattern, [int depth = 0]) {\n    if (depth > 10) throw ValidationException({pattern: [\'Maximum payload recursion depth exceeded.\']});'
  );
  s = s.replaceFirst(
      'results.addAll(_expandFieldPattern(nextPattern));',
      'results.addAll(_expandFieldPattern(nextPattern, depth + 1));'
  );
  s = s.replaceFirst(
      'results.addAll(_expandFieldPattern(nextPattern));',
      'results.addAll(_expandFieldPattern(nextPattern, depth + 1));'
  );
  f.writeAsStringSync(s);
}

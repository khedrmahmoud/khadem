import 'dart:io';

void main() {
  final f = File('lib/src/core/logging/logging_writers/file_writer.dart');
  var content = f.readAsStringSync();

  // Add Mutex import
  content = content.replaceFirst(
      'import ''package:khadem/src/contracts/logging/log_level.dart'';',
      'import ''package:khadem/src/contracts/logging/log_level.dart'';\nimport ''package:khadem/src/support/utils/mutex.dart'';'
  );

  // Add Mutex field
  content = content.replaceFirst(
       'bool _isRotating = false;',
       'bool _isRotating = false;\n  final Mutex _rotationLock = Mutex();'
  );

  // Use lock for rotate
  content = content.replaceFirst(
      'Future<void> _rotate(List<int> pendingBytes) async {',
      'Future<void> _rotate(List<int> pendingBytes) async {\n    await _rotationLock.acquire();'
  );

  content = content.replaceFirst(
      '} finally {\n      _isRotating = false;\n    }\n  }',
      '} finally {\n      _isRotating = false;\n      _rotationLock.release();\n    }\n  }'
  );

  f.writeAsStringSync(content);
}

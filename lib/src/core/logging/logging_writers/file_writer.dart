import 'dart:convert';
import 'dart:io';

import '../../contracts/logging/log_handler.dart';
import '../../contracts/logging/log_level.dart';

/// File-based log handler.
class FileLogHandler implements LogHandler {
  final File _logFile;
  final int _maxFileSizeBytes;
  final int _maxBackupCount;
  final bool _rotateOnSize;
  final bool _rotateDaily;
  final bool _formatJson;

  FileLogHandler({
    required String filePath,
    int maxFileSizeBytes = 5 * 1024 * 1024,
    int maxBackupCount = 5,
    bool rotateOnSize = true,
    bool rotateDaily = false,
    bool formatJson = true,
  })  : _logFile = File(filePath),
        _maxFileSizeBytes = maxFileSizeBytes,
        _maxBackupCount = maxBackupCount,
        _rotateOnSize = rotateOnSize,
        _rotateDaily = rotateDaily,
        _formatJson = formatJson {
    final dir = Directory(_logFile.parent.path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    if (!_logFile.existsSync()) {
      _logFile.createSync();
    }
    _rotateLogIfNeeded();
  }

  @override
  void log(LogLevel level, String message,
      {Map<String, dynamic>? context, StackTrace? stackTrace,}) {
    _rotateLogIfNeeded();

    final logEntry = _formatJson
        ? _formatJsonLog(level, message, context, stackTrace)
        : _formatTextLog(level, message, context, stackTrace);

    _logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
  }

  String _formatJsonLog(LogLevel level, String message,
      Map<String, dynamic>? context, StackTrace? stackTrace,) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.toString().split('.').last.toUpperCase(),
      'message': message,
      if (context != null) 'context': context,
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    return jsonEncode(logEntry);
  }

  String _formatTextLog(LogLevel level, String message,
      Map<String, dynamic>? context, StackTrace? stackTrace,) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    var log = '[$timestamp] [$levelStr] $message';

    if (context != null) {
      log += '\nContext: ${jsonEncode(context)}';
    }

    if (stackTrace != null) {
      log += '\nStack Trace:\n$stackTrace';
    }

    return log;
  }

  void _rotateLogIfNeeded() {
    if (_rotateOnSize &&
        _logFile.existsSync() &&
        _logFile.lengthSync() >= _maxFileSizeBytes) {
      _rotateLog();
    } else if (_rotateDaily && _logFile.existsSync()) {
      final lastModified = _logFile.lastModifiedSync();
      final now = DateTime.now();
      if (lastModified.year != now.year ||
          lastModified.month != now.month ||
          lastModified.day != now.day) {
        _rotateLog();
      }
    }
  }

  void _rotateLog() {
    for (var i = _maxBackupCount; i > 0; i--) {
      final backupFile = File('${_logFile.path}.$i');
      final previousBackupFile =
          i > 1 ? File('${_logFile.path}.${i - 1}') : _logFile;

      if (backupFile.existsSync()) {
        backupFile.deleteSync();
      }

      if (previousBackupFile.existsSync()) {
        previousBackupFile.copySync(backupFile.path);
      }
    }

    _logFile.writeAsStringSync('');
  }

  @override
  void close() {
    // No resources to close for file handler
  }
}

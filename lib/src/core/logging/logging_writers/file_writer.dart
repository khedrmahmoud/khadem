import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:khadem/src/contracts/logging/log_handler.dart';
import 'package:khadem/src/contracts/logging/log_level.dart';

/// File-based log handler with non-blocking I/O and buffering.
class FileLogHandler implements LogHandler {
  final File _logFile;
  final int _maxFileSizeBytes;
  final int _maxBackupCount;
  final bool _rotateOnSize;
  final bool _rotateDaily;
  final bool _formatJson;
  final LogLevel _minimumLevel;

  IOSink? _sink;
  int _currentFileSize = 0;
  DateTime _lastRotationDate;
  bool _isRotating = false;
  final Queue<List<int>> _buffer = Queue<List<int>>();

  FileLogHandler({
    required String filePath,
    int maxFileSizeBytes = 5 * 1024 * 1024,
    int maxBackupCount = 5,
    bool rotateOnSize = true,
    bool rotateDaily = false,
    bool formatJson = true,
    LogLevel minimumLevel = LogLevel.debug,
  })  : _logFile = File(filePath),
        _maxFileSizeBytes = maxFileSizeBytes,
        _maxBackupCount = maxBackupCount,
        _rotateOnSize = rotateOnSize,
        _rotateDaily = rotateDaily,
        _formatJson = formatJson,
        _minimumLevel = minimumLevel,
        _lastRotationDate = DateTime.now() {
    _initialize();
  }

  void _initialize() {
    final dir = _logFile.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    if (_logFile.existsSync()) {
      _currentFileSize = _logFile.lengthSync();
      _lastRotationDate = _logFile.lastModifiedSync();
    } else {
      _currentFileSize = 0;
    }

    _openSink();
  }

  void _openSink() {
    _sink = _logFile.openWrite(mode: FileMode.append);
  }

  @override
  LogLevel get minimumLevel => _minimumLevel;

  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    if (!level.isAtLeast(_minimumLevel)) return;

    final logEntry = _formatJson
        ? _formatJsonLog(level, message, context, stackTrace)
        : _formatTextLog(level, message, context, stackTrace);

    // On Windows (and in general), a String can contain malformed UTF-16
    // (e.g. from decoding arbitrary bytes). Ensure logging never throws.
    final bytes = _safeUtf8Encode('$logEntry\n');

    if (_isRotating) {
      _buffer.add(bytes);
      return;
    }

    if (_shouldRotate(bytes.length)) {
      _rotate(bytes);
      return;
    }

    _write(bytes);
  }

  void _write(List<int> bytes) {
    _sink?.add(bytes);
    _currentFileSize += bytes.length;
  }

  bool _shouldRotate(int newBytesLength) {
    if (_rotateOnSize &&
        (_currentFileSize + newBytesLength) >= _maxFileSizeBytes) {
      return true;
    }

    if (_rotateDaily) {
      final now = DateTime.now();
      if (_lastRotationDate.year != now.year ||
          _lastRotationDate.month != now.month ||
          _lastRotationDate.day != now.day) {
        return true;
      }
    }

    return false;
  }

  Future<void> _rotate(List<int> pendingBytes) async {
    _isRotating = true;
    _buffer.add(pendingBytes);

    try {
      await _sink?.flush();
      await _sink?.close();
      _sink = null;

      // Perform rotation
      await _rotateFiles();

      // Reset state
      _currentFileSize = 0;
      _lastRotationDate = DateTime.now();
      _openSink();

      // Flush buffer
      while (_buffer.isNotEmpty) {
        final bytes = _buffer.removeFirst();
        _write(bytes);
        // Note: We don't check for rotation again during flush to avoid infinite loops
        // if the buffer is larger than max file size.
      }
    } catch (e) {
      print('Error rotating logs: $e');
      // Try to recover
      if (_sink == null) _openSink();
    } finally {
      _isRotating = false;
    }
  }

  Future<void> _rotateFiles() async {
    // Remove the oldest backup first.
    final oldest = File('${_logFile.path}.$_maxBackupCount');
    if (await oldest.exists()) {
      await oldest.delete();
    }

    // Shift the remaining backups.
    for (var i = _maxBackupCount - 1; i >= 1; i--) {
      final source = File('${_logFile.path}.$i');
      final destination = File('${_logFile.path}.${i + 1}');
      if (await source.exists()) {
        await source.rename(destination.path);
      }
    }

    // Move the active log to .1, falling back to copy+truncate on Windows
    // when another process keeps the file handle open and rename fails.
    final primaryBackup = File('${_logFile.path}.1');
    if (await primaryBackup.exists()) {
      await primaryBackup.delete();
    }

    if (await _logFile.exists()) {
      try {
        await _logFile.rename(primaryBackup.path);
      } on FileSystemException {
        // On Windows, a locked file cannot be renamed. Copy its contents
        // and truncate the original so logging can continue.
        await _logFile.copy(primaryBackup.path);
        await _logFile.writeAsBytes(const []);
      }
    }
  }

  String _formatJsonLog(
    LogLevel level,
    String message,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  ) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.toString().split('.').last.toUpperCase(),
      'message': message,
      if (context != null) 'context': context,
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    return jsonEncode(logEntry);
  }

  String _formatTextLog(
    LogLevel level,
    String message,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  ) {
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

  @override
  void close() {
    _sink?.close();
    _sink = null;
  }

  List<int> _safeUtf8Encode(String input) {
    try {
      return utf8.encode(input);
    } catch (_) {
      return utf8.encode(_sanitizeUtf16(input));
    }
  }

  String _sanitizeUtf16(String input) {
    final buffer = StringBuffer();
    final units = input.codeUnits;

    for (var i = 0; i < units.length; i++) {
      final unit = units[i];

      // High surrogate
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        if (i + 1 < units.length) {
          final next = units[i + 1];
          // Valid low surrogate
          if (next >= 0xDC00 && next <= 0xDFFF) {
            buffer.writeCharCode(unit);
            buffer.writeCharCode(next);
            i++;
            continue;
          }
        }
        buffer.write('\uFFFD');
        continue;
      }

      // Low surrogate without a preceding high surrogate
      if (unit >= 0xDC00 && unit <= 0xDFFF) {
        buffer.write('\uFFFD');
        continue;
      }

      buffer.writeCharCode(unit);
    }

    return buffer.toString();
  }
}

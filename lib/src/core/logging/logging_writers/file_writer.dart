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

    final bytes = utf8.encode('$logEntry\n');

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
    for (var i = _maxBackupCount; i > 0; i--) {
      final backupFile = File('${_logFile.path}.$i');
      final previousBackupFile =
          i > 1 ? File('${_logFile.path}.${i - 1}') : _logFile;

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      if (await previousBackupFile.exists()) {
        await previousBackupFile.rename(backupFile.path);
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
}

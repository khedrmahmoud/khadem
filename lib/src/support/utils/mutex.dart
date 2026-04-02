import 'dart:async';

/// A simple mutual exclusion lock for asynchronous operations.
class Mutex {
  Completer<void>? _completer;

  Future<void> acquire() async {
    while (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
  }

  void release() {
    if (_completer != null && !_completer!.isCompleted) {
      final c = _completer;
      _completer = null;
      c!.complete();
    }
  }

  Future<T> protect<T>(Future<T> Function() action) async {
    await acquire();
    try {
      return await action();
    } finally {
      release();
    }
  }
}

import 'dart:collection';

/// Priority queue implementation using heap
class PriorityQueue<T extends Comparable<T>> {
  final SplayTreeSet<T> _heap;

  PriorityQueue() : _heap = SplayTreeSet<T>();

  /// Add item to queue
  void add(T item) {
    _heap.add(item);
  }

  /// Remove and return highest priority item
  T? removeFirst() {
    if (_heap.isEmpty) return null;
    final first = _heap.first;
    _heap.remove(first);
    return first;
  }

  /// Peek at highest priority item without removing
  T? peek() => _heap.isEmpty ? null : _heap.first;

  /// Get queue size
  int get length => _heap.length;

  /// Check if empty
  bool get isEmpty => _heap.isEmpty;

  /// Check if not empty
  bool get isNotEmpty => _heap.isNotEmpty;

  /// Clear the queue
  void clear() => _heap.clear();

  /// Get all items as list (sorted by priority)
  List<T> toList() => _heap.toList();

  /// Remove specific item
  bool remove(T item) => _heap.remove(item);

  /// Check if contains item
  bool contains(T item) => _heap.contains(item);
}

/// Job priority levels
enum JobPriority {
  low(0),
  normal(1),
  high(2),
  critical(3);

  final int value;
  const JobPriority(this.value);

  /// Compare priorities
  bool isHigherThan(JobPriority other) => value > other.value;

  /// Compare priorities
  bool isLowerThan(JobPriority other) => value < other.value;
}

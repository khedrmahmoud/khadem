mixin SoftDeletes {
  DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  void softDelete([DateTime? date]) {
    deletedAt = date ?? DateTime.now().toUtc();
  }

  void restore() {
    deletedAt = null;
  }
}

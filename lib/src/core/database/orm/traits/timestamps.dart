mixin Timestamps {
  DateTime? createdAt;
  DateTime? updatedAt;

  void touchCreated() {
    createdAt ??= DateTime.now().toUtc();
  }

  void touchUpdated() {
    updatedAt ??= DateTime.now().toUtc();
  }

  void touch() {
    touchUpdated();
    touchCreated();
  }
}

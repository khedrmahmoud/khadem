import 'package:uuid/uuid.dart';

mixin UuidPrimaryKey {
  String? uuid;

  static final Uuid _uuidGenerator = Uuid();

  void generateUuid() {
    uuid = _uuidGenerator.v4();
  }

  bool get hasUuid => uuid != null;
}

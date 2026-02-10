import 'package:khadem/contracts.dart' show Event;

class UserCreated extends Event {
  final Map<String, dynamic> payload;

  UserCreated(this.payload);
}

class UserUpdated extends Event {
  final Map<String, dynamic> payload;

  UserUpdated(this.payload);
}

class UserDeleted extends Event {
  final Map<String, dynamic> payload;

  UserDeleted(this.payload);
}

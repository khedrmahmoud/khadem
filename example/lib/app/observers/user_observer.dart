import 'package:khadem/database/orm.dart';

import '../models/user.dart';

class UserObserver extends ModelObserver<User> {
  @override
  void creating(User user) {
    print('A new user is being created: ${user.email}');
  }

  @override
  void saving(User user) {
    print('A user is being saved: ${user.email}');
  }
}

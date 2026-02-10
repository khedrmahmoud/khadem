 

import 'package:khadem/database/orm.dart';

class User extends KhademModel<User> with Timestamps {
  User({
    String? name,
    String? email,
    String? password,
    int? id,
  }) {
    this.id = id;
    if (name != null) this.name = name;
    if (email != null) this.email = email;
    if (password != null) this.password = password;
  }

  String? get name => getAttribute('name') as String?;
  set name(String? value) => setAttribute('name', value);

  String? get email => getAttribute('email') as String?;
  set email(String? value) => setAttribute('email', value);

  String? get password => getAttribute('password') as String?;
  set password(String? value) => setAttribute('password', value);

  @override
  List<String> get fillable => ['name', 'email', 'password'];

  @override
  List<String> get hidden => ['password'];

  @override
  Map<String, RelationDefinition> get definedRelations => {
        // 'posts': hasMany<Post>(
        //   foreignKey: 'user_id',
        //   relatedTable: 'posts',
        //   factory: () => Post(),
        // )
      };

  @override
  User newFactory(Map<String, dynamic> data) {
    return User()..fromJson(data);
  }
}

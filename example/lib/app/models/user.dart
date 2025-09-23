import 'package:khadem/khadem.dart'
    show KhademModel, RelationDefinition, HasRelationships, Timestamps;

class User extends KhademModel<User> with Timestamps, HasRelationships {
  User({
    this.name,
    this.email,
    this.password,
    int? id,
  }) {
    this.id = id;
  }

  String? name;
  String? email;
  String? password;

  @override
  List<String> get fillable =>
      ['name', 'email', 'password', 'created_at', 'updated_at'];

  @override
  List<String> get initialHidden => ['password'];

  @override
  List<String> get initialAppends => [];

  @override
  Map<String, dynamic> get computed => {};
  @override
  Object? getField(String key) {
    return switch (key) {
      'id' => id,
      'name' => name,
      'email' => email,
      'password' => password,
      'created_at' => createdAt,
      'updated_at' => updatedAt,
      _ => null
    };
  }

  @override
  void setField(String key, dynamic value) {
    return switch (key) {
      'id' => id = value,
      'name' => name = value,
      'email' => email = value,
      'password' => password = value,
      'created_at' => createdAt = value,
      'updated_at' => updatedAt = value,
      _ => null
    };
  }

  @override
  Map<String, RelationDefinition> get relations => {
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

import 'package:khadem/khadem.dart'
    show KhademModel, RelationDefinition, Timestamps;

class User extends KhademModel<User> with Timestamps {
  String? get name => getAttribute('name');

  String? get email => getAttribute('email');

  String? get password => getAttribute('password');

  @override
  Map<String, dynamic> get casts => {
        'created_at': DateTime,
        'updated_at': DateTime,
      };

  
  @override
  List<String> get fillable =>
      ['name', 'email', 'password', 'created_at', 'updated_at'];

  @override
  List<String> get hidden => ['password'];

  @override
  Map<String, dynamic> get appends => {
        'name_upper': () => (getAttribute('name') as String?)?.toUpperCase(),
      };

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

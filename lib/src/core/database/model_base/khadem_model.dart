import 'concerns/has_attributes.dart';
import 'concerns/has_events.dart';
import 'concerns/has_relations.dart';
import 'concerns/interacts_with_database.dart';

export '../orm/model_lifecycle.dart';
export 'concerns/has_attributes.dart';
export 'concerns/has_events.dart';
export 'concerns/has_relations.dart';
export 'concerns/interacts_with_database.dart';

abstract class KhademModel<T>
    with
        HasAttributes<T>,
        HasEvents<T>,
        HasRelations<T>,
        InteractsWithDatabase<T> {
  /// The primary key for the model.
  @override
  int? id;

  /// The table associated with the model.
  @override
  String get table => '${runtimeType.toString().toLowerCase()}s';

  /// Alias for table.
  @override
  String get tableName => table;

  /// The primary key associated with the table.
  @override
  String get primaryKey => 'id';

  /// Create a new instance of the model.
  KhademModel() {
    // Initialize defaults if needed
  }

  /// Create a new instance from a map.
  @override
  T newFactory(Map<String, dynamic> data);

  /// Sync the 'id' property with attributes.
  @override
  void setAttribute(String key, dynamic value) {
    super.setAttribute(key, value);
    if (key == primaryKey) {
      if (value is int) {
        id = value;
      } else if (value is String) {
        id = int.tryParse(value);
      }
    }
  }

  /// Initialize the model from a database record.
  @override
  void fromJson(Map<String, dynamic> json) {
    super.fromJson(json);
    if (json.containsKey(primaryKey)) {
      exists = true;
      // Sync ID
      setAttribute(primaryKey, json[primaryKey]);
    }
  }

  @override
  String toString() {
    return '$runtimeType(${toMap()})';
  }
}

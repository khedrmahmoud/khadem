import '../../../application/khadem.dart';
import '../../../contracts/database/query_builder_interface.dart';
import '../orm/relation_definition.dart';
import 'json_model.dart';
import 'relation_model.dart';
import 'event_model.dart';
import 'database_model.dart';

abstract class KhademModel<T> {
  int? id;

  late final JsonModel<T> json = JsonModel<T>(this);
  late final RelationModel<T> relation = RelationModel<T>(this);
  late final EventModel<T> event = EventModel<T>(this);
  late final DatabaseModel<T> db = DatabaseModel<T>(this);

  Map<String, dynamic> get rawData => json.rawData;

  /// Used to generate instances inside query builder
  T newFactory(Map<String, dynamic> data);

  /// Used in serialization
  List<String> get fillable => [];
  List<String> get hidden => [];
  List<String> get appends => [];
  Map<String, Type> get casts => {};
  Map<String, dynamic> get computed => {};

  /// Holds all relations
  Map<String, RelationDefinition> get relations => {};

  /// Access fields
  dynamic getField(String key) => UnimplementedError();

  void setField(String key, dynamic value) => UnimplementedError();

  /// Query builder
  QueryBuilderInterface<T> get query =>
      Khadem.db.table<T>(tableName, modelFactory: (data) => newFactory(data));

  String get modelName => runtimeType.toString();
  String get tableName => '${runtimeType.toString().toLowerCase()}s';

  /// Delegates
  Map<String, dynamic> toJson() => {
        ...json.toJson(),
        ...relation.toJson(),
      };

  Map<String, dynamic> toDatabaseJson() => json.toDatabaseJson();

  void fromJson(Map<String, dynamic> data) {
    json.fromJson(data);
  }

  /// Persistence
  Future<void> save() => db.save();
  Future<void> delete() => db.delete();
}

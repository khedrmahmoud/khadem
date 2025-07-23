import '../../../contracts/database/query_builder_interface.dart';
import '../../../application/khadem.dart';
import '../../../support/helpers/date_helper.dart';
import '../orm/model_events.dart';
import '../orm/relation_definition.dart';

/// Base model that all application models should extend.
@Deprecated('Use KhademModel instead')
abstract class BaseModel<T> {
  /// ID of the model.
  int? id;

  /// Holds all raw data received from fromJson
  Map<String, dynamic> _rawData = {};
  Map<String, dynamic> get rawData => _rawData;

  /// Database table name.
  String get tableName => '${runtimeType.toString().toLowerCase()}s';

  /// The name of the model.
  String get modelName => runtimeType.toString();

  /// Fields allowed for mass assignment.
  List<String> get fillable => [];

  /// Fields that should be hidden when serializing.
  List<String> get hidden => [];

  /// Fields that should be cast to specific types.
  Map<String, Type> get casts => {};

  /// Fields to append to the model when serializing.
  List<String> get appends => [];

  /// Computed properties for the model.
  Map<String, dynamic> get computed => {};

  T newFactory(Map<String, dynamic> data) => throw UnimplementedError(
      'newFactory must be implemented in the child model');

  /// Create query builder using current default connection.
  QueryBuilderInterface<T> get query =>
      Khadem.db.table<T>(tableName, modelFactory: (data) => newFactory(data));

  /// Holds all relations
  Map<String, RelationDefinition> get relations => {};

  final Map<String, dynamic> _loadedRelations = {};

  void setRelation(String key, dynamic value) {
    _loadedRelations[key] = value;
  }

  dynamic getRelation(String key) => _loadedRelations[key];

  /// Converts model data to JSON for saving to database.
  /// This does NOT hide fields like password.
  Map<String, dynamic> toDatabaseJson() {
    final data = <String, dynamic>{};

    for (final key in fillable) {
      final value = getField(key);
      if (value is DateTime) {
        data[key] = value.toUtc();
      } else {
        data[key] = value;
      }
    }

    return data;
  }

  /// Converts model to JSON for API responses.
  /// This respects `hidden`, `appends`, and `computed`.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      if (id != null) 'id': id,
    };

    for (final key in _rawData.keys) {
      if (!hidden.contains(key)) {
        final value = getField(key);
        data[key] = value is DateTime ? DateHelper.toResponse(value) : value;
      }
    }

    for (final key in appends) {
      data[key] = computed[key];
    }
    // ✅ Add loaded relations
    for (final entry in _loadedRelations.entries) {
      if (!hidden.contains(entry.key)) {
        final value = entry.value;
        data[entry.key] = value;
      }
    }
    return data;
  }

  /// Fills model data from a map (e.g., database).
  void fromJson(Map<String, dynamic> json) {
    _rawData = Map<String, dynamic>.from(json); // Store raw data

    id = json['id'];
    for (final key in json.keys) {
      var value = json[key];
      // Apply casts
      if (casts.containsKey(key)) {
        final castType = casts[key];
        if (castType == DateTime && value is String) {
          value = DateTime.tryParse(value);
        } else if (castType == int && value is String) {
          value = int.tryParse(value);
        } else if (castType == double && value is String) {
          value = double.tryParse(value);
        } else if (castType == bool && value is String) {
          value = value.toLowerCase() == 'true' ? true : false;
        }
      }

      setField(key, value);
    }
  }

  /// Override this method to define how each field is accessed.
  dynamic getField(String key) {
    throw UnimplementedError('getField must be implemented in the child model');
  }

  /// Override this method to define how each field is set.
  void setField(String key, dynamic value) {
    throw UnimplementedError('setField must be implemented in the child model');
  }

  BaseModel copyWith({int? id}) {
    this.id = id;
    return this;
  }

  /// Saves the model to the database.
  Future<void> save() async {
    if (id != null) {
      await beforeUpdate();
      await query.where('id', '=', id).update(toDatabaseJson());
      await afterUpdate();
    } else {
      await beforeCreate();
      await query.insert(toDatabaseJson());
      await afterCreate();
    }
  }

  /// Deletes the model.
  Future<void> delete() async {
    await beforeDelete();
    await query.where('id', '=', id).delete();
    await afterDelete();
  }

  /// Triggers a model event.
  Future<void> fireEvent(String Function(String) eventNameBuilder) async {
    await Khadem.eventBus.emit(eventNameBuilder(modelName.toLowerCase()), this);
  }

  // 🪝 Lifecycle hooks

  Future<void> beforeCreate() async => await fireEvent(ModelEvents.creating);
  Future<void> afterCreate() async => await fireEvent(ModelEvents.created);
  Future<void> beforeUpdate() async => await fireEvent(ModelEvents.updating);
  Future<void> afterUpdate() async => await fireEvent(ModelEvents.updated);
  Future<void> beforeDelete() async => await fireEvent(ModelEvents.deleting);
  Future<void> afterDelete() async => await fireEvent(ModelEvents.deleted);
  Future<void> beforeRestore() async => await fireEvent(ModelEvents.restoring);
  Future<void> afterRestore() async => await fireEvent(ModelEvents.restored);
}

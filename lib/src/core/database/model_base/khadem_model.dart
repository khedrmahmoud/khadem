import 'package:khadem/khadem.dart' show QueryBuilderInterface, Khadem;

import '../orm/relation_definition.dart';
import '../orm/relation_type.dart';
import 'database_model.dart';
import 'event_model.dart';
import 'json_model.dart';
import 'relation_model.dart';

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

  /// Hidden attributes
  List<String> get hidden => _hiddenList;

  /// Appended attributes (computed)
  List<String> get appends => _appendsList;

  /// Type casting for fields
  Map<String, Type> get casts => {};

  /// Computed properties (getters)
  /// E.g., 'full_name': () => '$firstName $lastName'
  /// These are included when listed in `appends`
  Map<String, dynamic> get computed => {};

  /// Default relations to eager load on all queries
  /// 
  /// Define relations that should always be loaded when querying this model.
  /// These will be automatically applied to get(), first(), findById(), and paginate().
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// List<dynamic> get withRelations => ['posts', 'profile'];
  /// // or with nested relations:
  /// List<dynamic> get withRelations => ['posts.comments', 'profile', 'roles'];
  /// ```
  /// 
  /// You can override this behavior in queries:
  /// - `query.without(['posts']).get()` - Exclude specific relations
  /// - `query.withOnly(['messages']).get()` - Replace default relations
  /// - `query.withRelations(['extra'])` - Add to default relations (in query)
  List<dynamic> get defaultRelations => [];

  /// Mutable backing fields for hidden and appends
  late final List<String> _hiddenList = _getInitialHidden();
  late final List<String> _appendsList = _getInitialAppends();

  ///  Initial hidden can be overridden
  List<String> get initialHidden => [];

  /// Initial appends can be overridden
  List<String> get initialAppends => [];

  List<String> _getInitialHidden() => List.from(initialHidden);
  List<String> _getInitialAppends() => List.from(initialAppends);

  /// Holds all relations
  Map<String, RelationDefinition> get relations => {};

  /// Access fields
  dynamic getField(String key) => UnimplementedError();

  void setField(String key, dynamic value) => UnimplementedError();

  /// Query builder
  QueryBuilderInterface<T> get query =>
      Khadem.db.table(tableName, modelFactory: (data) => newFactory(data));

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
  Future<void> refresh() => db.refresh();
  Future<T?> findById(dynamic id) => db.findById(id);
  Future<List<T>> findWhere(String column, String operator, dynamic value) =>
      db.findWhere(column, operator, value);

  /// Load relations eagerly
  Future<T> load(List<String> relations) async {
    for (final relationName in relations) {
      await _loadRelation(relationName);
    }
    return this as T;
  }

  /// Load a single relation
  Future<T> loadRelation(String relationName) async {
    await _loadRelation(relationName);
    return this as T;
  }

  /// Load relations if they haven't been loaded yet
  Future<T> loadMissing(List<String> relations) async {
    for (final relationName in relations) {
      if (!relation.isLoaded(relationName)) {
        await _loadRelation(relationName);
      }
    }
    return this as T;
  }

  /// Check if a relation is loaded
  bool isRelationLoaded(String relationName) {
    return relation.isLoaded(relationName);
  }

  /// Get a loaded relation
  dynamic getRelation(String relationName) {
    return relation.get(relationName);
  }

  /// Set a relation value
  void setRelation(String relationName, dynamic value) {
    relation.set(relationName, value);
  }

  /// Append computed attributes to the model
  T append(List<String> attributes) {
    for (final attribute in attributes) {
      _appendAttribute(attribute);
    }
    return this as T;
  }

  /// Append a single attribute
  T appendAttribute(String attribute) {
    _appendAttribute(attribute);
    return this as T;
  }

  /// Set an appended attribute value
  void setAppended(String key) {
    appends.add(key);
  }

  /// Get an appended attribute value
  dynamic getAppended(String key) {
    return appends.contains(key) ? _getComputedAttribute(key) : null;
  }

  /// Check if an attribute is appended
  bool hasAppended(String key) {
    return appends.contains(key);
  }

  /// Make a model visible (opposite of hidden)
  T makeVisible(List<String> attributes) {
    hidden.removeWhere((attr) => attributes.contains(attr));
    return this as T;
  }

  /// Make a model hidden
  T makeHidden(List<String> attributes) {
    hidden.addAll(attributes.where((attr) => !hidden.contains(attr)));
    return this as T;
  }

  /// Get only specified attributes
  Map<String, dynamic> only(List<String> attributes) {
    final result = <String, dynamic>{};
    final jsonData = toJson();

    for (final attribute in attributes) {
      if (jsonData.containsKey(attribute)) {
        result[attribute] = jsonData[attribute];
      }
    }

    return result;
  }

  /// Get all attributes except specified ones
  Map<String, dynamic> except(List<String> attributes) {
    final result = Map<String, dynamic>.from(toJson());

    for (final attribute in attributes) {
      result.remove(attribute);
    }

    return result;
  }

  /// Private helper methods
  Future<void> _loadRelation(String relationName) async {
    if (!relations.containsKey(relationName)) {
      throw Exception(
        'Relation "$relationName" not defined on model $modelName',
      );
    }

    final relationDef = relations[relationName]!;
    final relatedModels = await _fetchRelatedModels(relationDef);

    relation.set(relationName, relatedModels);
  }

  Future<dynamic> _fetchRelatedModels(RelationDefinition relationDef) async {
    final localValue = getField(relationDef.localKey);
    if (localValue == null) return null;

    switch (relationDef.type) {
      case RelationType.hasOne:
      case RelationType.belongsTo:
        var query = Khadem.db
            .table(
              relationDef.relatedTable,
              modelFactory: (data) => relationDef.factory().newFactory(data),
            )
            .where(relationDef.foreignKey, '=', localValue);
        if (relationDef.query != null) {
          query = relationDef.query!(query);
        }
        return query.first();

      case RelationType.hasMany:
        var query = Khadem.db
            .table(
              relationDef.relatedTable,
              modelFactory: (data) => relationDef.factory().newFactory(data),
            )
            .where(relationDef.foreignKey, '=', localValue);
        if (relationDef.query != null) {
          query = relationDef.query!(query);
        }
        return query.get();

      case RelationType.belongsToMany:
        // For many-to-many, we'd need pivot table logic
        // This is a simplified implementation
        var query = Khadem.db
            .table(
              relationDef.relatedTable,
              modelFactory: (data) => relationDef.factory().newFactory(data),
            )
            .where(relationDef.foreignKey, '=', localValue);
        if (relationDef.query != null) {
          query = relationDef.query!(query);
        }
        return query.get();

      default:
        throw UnsupportedError(
          'Relation type ${relationDef.type} not implemented',
        );
    }
  }

  void _appendAttribute(String attribute) {
    if (!appends.contains(attribute)) {
      setAppended(attribute);
    }
  }

  /// Get a computed attribute value
  dynamic getComputedAttribute(String attribute) {
    return _getComputedAttribute(attribute);
  }

  dynamic _getComputedAttribute(String attribute) {
    // Check if it's in computed properties
    if (computed.containsKey(attribute)) {
      final computedValue = computed[attribute];
      if (computedValue is Function) {
        return computedValue();
      }
      return computedValue;
    }

    // For now, return null if not found in computed
    // In a full implementation, you might use reflection or code generation
    return null;
  }
}

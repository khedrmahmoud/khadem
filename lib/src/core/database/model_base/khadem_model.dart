import 'package:khadem/khadem.dart' show QueryBuilderInterface, Khadem;

import '../orm/observers/observer_registry.dart';
import '../orm/observers/model_observer.dart';
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

  /// Register an observer for this model type.
  ///
  /// Observers provide a clean way to handle model lifecycle events
  /// outside of the model itself.
  ///
  /// Example:
  /// ```dart
  /// class UserObserver extends ModelObserver<User> {
  ///   @override
  ///   void creating(User user) {
  ///     user.uuid = Uuid().v4();
  ///   }
  ///
  ///   @override
  ///   void created(User user) {
  ///     sendWelcomeEmail(user);
  ///   }
  /// }
  ///
  /// // Register the observer
  /// User.observe(UserObserver());
  /// ```
  static void observe<T extends KhademModel<T>>(ModelObserver<T> observer) {
    ObserverRegistry().register<T>(observer);
  }

  /// Used to generate instances inside query builder
  T newFactory(Map<String, dynamic> data);

  /// Used in serialization
  List<String> get fillable => [];

  /// Attributes that are NOT mass assignable
  /// 
  /// Define which attributes should be protected from mass assignment.
  /// When both `fillable` and `guarded` are empty, all attributes are fillable.
  /// When `fillable` is specified, `guarded` is ignored.
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// List<String> get guarded => ['id', 'created_at', 'updated_at'];
  /// ```
  List<String> get guarded => [];

  /// Attributes that should never be included in JSON
  /// 
  /// These attributes are completely hidden from serialization,
  /// even if explicitly requested. Use for sensitive data like passwords,
  /// API keys, etc.
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// List<String> get protected => ['password', 'api_key', 'secret'];
  /// ```
  List<String> get protected => [];

  /// Hidden attributes
  List<String> get hidden => _hiddenList;

  /// Appended attributes (computed)
  List<String> get appends => _appendsList;

  /// Type casting for fields
  /// Type casting for attributes
  /// 
  /// Supports both legacy Type-based casts and new AttributeCaster instances:
  /// 
  /// ```dart
  /// // Legacy (still supported):
  /// Map<String, dynamic> get casts => {
  ///   'created_at': DateTime,
  ///   'count': int,
  /// };
  /// 
  /// // New advanced casters:
  /// Map<String, dynamic> get casts => {
  ///   'settings': JsonCast(),
  ///   'roles': ArrayCast(),
  ///   'password': EncryptedCast(),
  /// };
  /// ```
  Map<String, dynamic> get casts => {};

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

  /// Cache for computed property values to prevent multiple evaluations
  final Map<String, dynamic> _computedCache = {};
  final Map<String, Future<dynamic>> _computedAsyncCache = {};
  Map<String, dynamic>? _computedAttributesCache;
  Future<Map<String, dynamic>>? _computedAttributesAsyncCache;

  /// Clear computed property cache
  /// 
  /// Call this when model data changes to ensure computed properties
  /// are re-evaluated on next access.
  void _clearComputedCache() {
    _computedCache.clear();
    _computedAsyncCache.clear();
    _computedAttributesCache = null;
    _computedAttributesAsyncCache = null;
  }

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
        ..._getComputedAttributes(),
      };

  /// Async version of toJson() that supports async computed properties
  /// 
  /// Use this when your model has async computed properties in `appends`.
  /// This will properly await async computed values.
  /// 
  /// Example:
  /// ```dart
  /// final user = await User.query().first();
  /// final json = await user.toJsonAsync();
  /// print(json['display_name']); // Async computed property resolved
  /// ```
  Future<Map<String, dynamic>> toJsonAsync() async {
    return {
      ...await json.toJsonAsync(),
      ...relation.toJson(),
    }..addAll(await _getComputedAttributesAsync());
  }

  Map<String, dynamic> toDatabaseJson() => json.toDatabaseJson();

  void fromJson(Map<String, dynamic> data) {
    json.fromJson(data);
    _clearComputedCache(); // Clear cache when model data changes
  }

  /// Mass assign attributes respecting fillable/guarded rules
  /// 
  /// Fills the model with data from a map, respecting the fillable and guarded
  /// attribute lists. Only fillable attributes will be assigned.
  /// 
  /// Example:
  /// ```dart
  /// final user = User()
  ///   ..fill({
  ///     'name': 'John',
  ///     'email': 'john@example.com',
  ///     'role': 'admin', // Ignored if not in fillable
  ///   });
  /// ```
  T fill(Map<String, dynamic> attributes) {
    json.fromJson(attributes, force: false);
    _clearComputedCache(); // Clear cache when model data changes
    return this as T;
  }

  /// Force fill attributes, bypassing fillable/guarded protection
  /// 
  /// Use with caution - this bypasses security restrictions.
  /// Useful for internal operations where you need to set guarded attributes.
  T forceFill(Map<String, dynamic> attributes) {
    json.fromJson(attributes, force: true);
    _clearComputedCache(); // Clear cache when model data changes
    return this as T;
  }

  /// Persistence
  Future<void> save() => db.save();
  Future<void> delete() => db.delete();
  Future<void> refresh() {
    _clearComputedCache(); // Clear cache when model data changes
    return db.refresh();
  }
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

  /// Get a relation, loading it if it's in defaultRelations and not loaded yet
  Future<dynamic> getRelationAsync<T>(String relationName) async {
    if (!relation.isLoaded(relationName) && defaultRelations.contains(relationName)) {
      await loadRelation(relationName);
    }
    return relation.get(relationName) as T;
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

  /// Get a computed attribute value (synchronous)
  /// 
  /// Returns the computed value if it's synchronous.
  /// For async computed properties, use `getComputedAttributeAsync()` instead.
  /// If the computed property is async, this will return null.
  dynamic getComputedAttribute(String attribute) {
    return _getComputedAttribute(attribute);
  }

  dynamic _getComputedAttribute(String attribute) {
    // Check cache first
    if (_computedCache.containsKey(attribute)) {
      return _computedCache[attribute];
    }

    // Check if it's in computed properties
    if (computed.containsKey(attribute)) {
      final computedValue = computed[attribute];
      if (computedValue is Function) {
        try {
          final result = computedValue();
          // If result is a Future, return null (use getComputedAttributeAsync instead)
          if (result is Future) {
            return null;
          }
          // Cache the result
          _computedCache[attribute] = result;
          return result;
        } catch (e) {
          // Cache null on error
          _computedCache[attribute] = null;
          return null;
        }
      }
      // Cache non-function values too
      _computedCache[attribute] = computedValue;
      return computedValue;
    }

    return null;
  }

  /// Get a computed attribute value (async-safe)
  /// 
  /// This method handles both synchronous and asynchronous computed properties.
  /// Use this when you need to support async computed properties.
  /// 
  /// Example:
  /// ```dart
  /// final displayName = await model.getComputedAttributeAsync('display_name');
  /// ```
  Future<dynamic> getComputedAttributeAsync(String attribute) async {
    return  _getComputedAttributeAsync(attribute);
  }

  Future<dynamic> _getComputedAttributeAsync(String attribute) async {
    // Check cache first
    if (_computedAsyncCache.containsKey(attribute)) {
      return _computedAsyncCache[attribute];
    }

    // Check if it's in computed properties
    if (computed.containsKey(attribute)) {
      final computedValue = computed[attribute];
      if (computedValue is Function) {
        try {
          final result = computedValue();
          // If result is a Future, await it
          if (result is Future) {
            final asyncResult = await result;
            // Cache the Future itself for future calls
            _computedAsyncCache[attribute] = result;
            return asyncResult;
          }
          // Cache non-async results too
          _computedAsyncCache[attribute] = Future.value(result);
          return result;
        } catch (e) {
          // Cache null on error
          _computedAsyncCache[attribute] = Future.value(null);
          return null;
        }
      }
      // Cache non-function values
      _computedAsyncCache[attribute] = Future.value(computedValue);
      return computedValue;
    }

    return null;
  }

  /// Helper method to get all computed attributes (sync)
  Map<String, dynamic> _getComputedAttributes() {
    if (_computedAttributesCache != null) {
      return _computedAttributesCache!;
    }
    
    final result = <String, dynamic>{};
    for (final key in appends) {
      result[key] = getComputedAttribute(key);
    }
    
    _computedAttributesCache = result;
    return result;
  }

  /// Helper method to get all computed attributes (async)
  Future<Map<String, dynamic>> _getComputedAttributesAsync() async {
    if (_computedAttributesAsyncCache != null) {
      return _computedAttributesAsyncCache!;
    }
    
    final result = <String, dynamic>{};
    for (final key in appends) {
      result[key] = await getComputedAttributeAsync(key);
    }
    
    _computedAttributesAsyncCache = Future.value(result);
    return result;
  }
}

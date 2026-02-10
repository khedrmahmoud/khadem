import '../../../../contracts/database/query_builder_interface.dart';
import '../../orm/eager_loader.dart';
import '../../orm/relation_definition.dart';
import '../../orm/relation_type.dart';
import '../../orm/relations/relation.dart';
import '../khadem_model.dart';

mixin HasRelations<T> {
  /// The loaded relationships for the model.
  final Map<String, dynamic> _relations = {};

  /// Get a relation instance.
  Relation<dynamic, dynamic> relation(String name) {
    if (!definedRelations.containsKey(name)) {
      throw Exception('Relation $name not defined');
    }
    return definedRelations[name]!.toRelation(this as KhademModel, name);
  }

  /// The relationships that should be eager loaded on every query.
  List<dynamic> get withRelations => [];

  /// The relationship counts that should be eager loaded on every query.
  List<String> get withCount => [];

  /// The defined relationships for the model.
  /// Override this to define relations.
  Map<String, RelationDefinition> get definedRelations => {};

  /// Get all the loaded relations.
  Map<String, dynamic> get relations => _relations;

  /// Determine if the given relation is loaded.
  bool relationLoaded(String key) => _relations.containsKey(key);

  /// Set the specific relationship in the model.
  void setRelation(String relation, dynamic value) {
    _relations[relation] = value;
  }

  /// Get a specified relationship.
  dynamic getRelation(String relation) {
    return _relations[relation];
  }

  /// Load the given relations.
  Future<T> load(List<String> relations) async {
    await EagerLoader.loadRelations([this as KhademModel], relations);
    return this as T;
  }

  /// Load the given relations if they are not already loaded.
  Future<T> loadMissing(List<String> relations) async {
    final relationsToLoad =
        relations.where((name) => !relationLoaded(name)).toList();
    if (relationsToLoad.isNotEmpty) {
      await load(relationsToLoad);
    }
    return this as T;
  }

  // ---------------------------------------------------------------------------
  // Relation Definitions
  // ---------------------------------------------------------------------------

  /// Define a one-to-one relationship.
  ///
  /// [foreignKey] is the column on the related model.
  /// [localKey] is the column on the current model (default: id).
  RelationDefinition hasOne<R extends KhademModel<R>>({
    required String foreignKey,
    required String relatedTable,
    required R Function() factory,
    String? localKey,
    Function(QueryBuilderInterface)? query,
  }) {
    final resolvedLocalKey = localKey ?? (this as KhademModel).primaryKey;
    return RelationDefinition<R>(
      type: RelationType.hasOne,
      localKey: resolvedLocalKey,
      foreignKey: foreignKey,
      relatedTable: relatedTable,
      factory: factory,
      query: query,
    );
  }

  /// Define a one-to-many relationship.
  ///
  /// [foreignKey] is the column on the related model.
  /// [localKey] is the column on the current model (default: id).
  RelationDefinition hasMany<R extends KhademModel<R>>({
    required String foreignKey,
    required String relatedTable,
    required R Function() factory,
    String? localKey,
    Function(QueryBuilderInterface)? query,
  }) {
    final resolvedLocalKey = localKey ?? (this as KhademModel).primaryKey;
    return RelationDefinition<R>(
      type: RelationType.hasMany,
      localKey: resolvedLocalKey,
      foreignKey: foreignKey,
      relatedTable: relatedTable,
      factory: factory,
      query: query,
    );
  }

  /// Define an inverse one-to-one or many-to-one relationship.
  ///
  /// [foreignKey] is the column on the current model.
  /// [ownerKey] is the column on the related model (default: id).
  RelationDefinition belongsTo<R extends KhademModel<R>>({
    required String relatedTable,
    required R Function() factory,
    required String foreignKey,
    String? ownerKey,
    Function(QueryBuilderInterface)? query,
  }) {
    final resolvedOwnerKey = ownerKey ?? factory().primaryKey;
    return RelationDefinition<R>(
      type: RelationType.belongsTo,
      localKey: '', // Not used for belongsTo in new definition
      foreignKey: foreignKey,
      ownerKey: resolvedOwnerKey,
      relatedTable: relatedTable,
      factory: factory,
      query: query,
    );
  }

  /// Define a many-to-many relationship.
  ///
  /// [pivotTable] is the intermediate table name.
  /// [foreignPivotKey] is the column on pivot table for current model.
  /// [relatedPivotKey] is the column on pivot table for related model.
  /// [parentKey] is the column on current model (default: id).
  /// [relatedKey] is the column on related model (default: id).
  RelationDefinition belongsToMany<R extends KhademModel<R>>({
    required String pivotTable,
    required String foreignPivotKey,
    required String relatedPivotKey,
    required String relatedTable,
    required R Function() factory,
    String? parentKey,
    String relatedKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    final resolvedParentKey = parentKey ?? (this as KhademModel).primaryKey;
    return RelationDefinition<R>(
      type: RelationType.belongsToMany,
      localKey: resolvedParentKey,
      foreignKey:
          'id', // Not directly used in belongsToMany logic in definition
      relatedKey: relatedKey,
      relatedTable: relatedTable,
      factory: factory,
      pivotTable: pivotTable,
      foreignPivotKey: foreignPivotKey,
      relatedPivotKey: relatedPivotKey,
      query: query,
    );
  }

  RelationDefinition morphOne<R extends KhademModel<R>>({
    required String morphName,
    required String relatedTable,
    required R Function() factory,
    String? localKey,
    Function(QueryBuilderInterface)? query,
  }) {
    final resolvedLocalKey = localKey ?? (this as KhademModel).primaryKey;
    return RelationDefinition<R>(
      type: RelationType.morphOne,
      localKey: resolvedLocalKey,
      foreignKey: '${morphName}_id',
      relatedTable: relatedTable,
      factory: factory,
      morphIdField: '${morphName}_id',
      morphTypeField: '${morphName}_type',
      query: query,
    );
  }

  RelationDefinition morphMany<R extends KhademModel<R>>({
    required String morphName,
    required String relatedTable,
    required R Function() factory,
    String? localKey,
    Function(QueryBuilderInterface)? query,
  }) {
    final resolvedLocalKey = localKey ?? (this as KhademModel).primaryKey;
    return RelationDefinition<R>(
      type: RelationType.morphMany,
      localKey: resolvedLocalKey,
      foreignKey: '${morphName}_id',
      relatedTable: relatedTable,
      factory: factory,
      morphIdField: '${morphName}_id',
      morphTypeField: '${morphName}_type',
      query: query,
    );
  }

  /// Define a "has one through" relationship with clearer parameter names.
  ///
  /// Key meanings:
  /// - [throughForeignKey]: column on the *through table* that points to the parent.
  ///   Example: `users.country_id`.
  /// - [relatedForeignKey]: column on the *related table* that points to the through table.
  ///   Example: `posts.user_id`.
  /// - [parentLocalKey]: column on the parent model used for matching (default: `id`).
  ///   Example: `countries.id`.
  /// - [throughLocalKey]: column on the through table used in the JOIN (default: `id`).
  ///   Example: `users.id`.
  RelationDefinition hasOneThrough<R extends KhademModel<R>>({
    required String throughTable,
    required String throughForeignKey,
    required String relatedForeignKey,
    required String relatedTable,
    required R Function() factory,
    String? parentLocalKey,
    String throughLocalKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    final resolvedParentLocalKey =
        parentLocalKey ?? (this as KhademModel).primaryKey;
    return RelationDefinition<R>(
      type: RelationType.hasOneThrough,
      localKey: resolvedParentLocalKey,
      foreignKey: '',
      relatedTable: relatedTable,
      factory: factory,
      throughTable: throughTable,
      firstKey: throughForeignKey,
      secondKey: relatedForeignKey,
      secondLocalKey: throughLocalKey,
      query: query,
    );
  }

  /// Define a "has many through" relationship with clearer parameter names.
  ///
  /// See [hasOneThroughVia] for the key meanings; the mapping is identical,
  /// but this relation returns a list of related models.
  RelationDefinition hasManyThrough<R extends KhademModel<R>>({
    required String throughTable,
    required String throughForeignKey,
    required String relatedForeignKey,
    required String relatedTable,
    required R Function() factory,
    String? parentLocalKey,
    String throughLocalKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    final resolvedParentLocalKey =
        parentLocalKey ?? (this as KhademModel).primaryKey;
    return RelationDefinition<R>(
      type: RelationType.hasManyThrough,
      localKey: resolvedParentLocalKey,
      foreignKey: '',
      relatedTable: relatedTable,
      factory: factory,
      throughTable: throughTable,
      firstKey: throughForeignKey,
      secondKey: relatedForeignKey,
      secondLocalKey: throughLocalKey,
      query: query,
    );
  }

  /// Define a polymorphic many-to-many relationship.
  ///
  /// [morphName] is the base name used for the type column on the pivot table.
  RelationDefinition morphToMany<R extends KhademModel<R>>({
    required String morphName,
    required String pivotTable,
    required String foreignPivotKey,
    required String relatedPivotKey,
    required String relatedTable,
    required R Function() factory,
    String parentKey = 'id',
    String relatedKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.morphToMany,
      localKey: parentKey,
      foreignKey: '',
      relatedKey: relatedKey,
      relatedTable: relatedTable,
      factory: factory,
      pivotTable: pivotTable,
      foreignPivotKey: foreignPivotKey,
      relatedPivotKey: relatedPivotKey,
      morphTypeField: '${morphName}_type',
      query: query,
    );
  }

  /// Define the inverse of a polymorphic many-to-many relationship.
  RelationDefinition morphedByMany<R extends KhademModel<R>>({
    required String morphName,
    required String pivotTable,
    required String foreignPivotKey,
    required String relatedPivotKey,
    required String relatedTable,
    required R Function() factory,
    String parentKey = 'id',
    String relatedKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.morphedByMany,
      localKey: parentKey,
      foreignKey: '',
      relatedKey: relatedKey,
      relatedTable: relatedTable,
      factory: factory,
      pivotTable: pivotTable,
      foreignPivotKey: foreignPivotKey,
      relatedPivotKey: relatedPivotKey,
      morphTypeField: '${morphName}_type',
      query: query,
    );
  }

  /// Define a polymorphic inverse relationship (fixed target type).
  ///
  /// This is like `belongsTo`, but it only loads if the `[morphName]_type`
  /// matches the target model type.
  RelationDefinition morphTo<R extends KhademModel<R>>({
    required String morphName,
    required String relatedTable,
    required R Function() factory,
    String ownerKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.morphTo,
      localKey: '',
      foreignKey: '${morphName}_id',
      ownerKey: ownerKey,
      relatedTable: relatedTable,
      factory: factory,
      morphIdField: '${morphName}_id',
      morphTypeField: '${morphName}_type',
      query: query,
    );
  }
}

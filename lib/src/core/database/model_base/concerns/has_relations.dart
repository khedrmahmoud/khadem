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

  RelationDefinition hasOne<R extends KhademModel<R>>({
    required String foreignKey,
    required String relatedTable,
    required R Function() factory,
    String localKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.hasOne,
      localKey: localKey,
      foreignKey: foreignKey,
      relatedTable: relatedTable,
      factory: factory,
      query: query,
    );
  }

  RelationDefinition hasMany<R extends KhademModel<R>>({
    required String foreignKey,
    required String relatedTable,
    required R Function() factory,
    String localKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.hasMany,
      localKey: localKey,
      foreignKey: foreignKey,
      relatedTable: relatedTable,
      factory: factory,
      query: query,
    );
  }

  RelationDefinition belongsTo<R extends KhademModel<R>>({
    required String localKey,
    required String relatedTable,
    required R Function() factory,
    String foreignKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.belongsTo,
      localKey: localKey,
      foreignKey: foreignKey,
      relatedTable: relatedTable,
      factory: factory,
      query: query,
    );
  }

  RelationDefinition belongsToMany<R extends KhademModel<R>>({
    required String pivotTable,
    required String foreignPivotKey,
    required String relatedPivotKey,
    required String relatedTable,
    required String localKey,
    required R Function() factory,
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.belongsToMany,
      localKey: localKey,
      foreignKey: 'id',
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
    String localKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.morphOne,
      localKey: localKey,
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
    String localKey = 'id',
    Function(QueryBuilderInterface)? query,
  }) {
    return RelationDefinition<R>(
      type: RelationType.morphMany,
      localKey: localKey,
      foreignKey: '${morphName}_id',
      relatedTable: relatedTable,
      factory: factory,
      morphIdField: '${morphName}_id',
      morphTypeField: '${morphName}_type',
      query: query,
    );
  }
}

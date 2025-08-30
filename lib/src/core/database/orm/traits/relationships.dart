import '../relation_type.dart';
import '../../model_base/khadem_model.dart';
import '../relation_definition.dart';

/// Utilities to define Eloquent-style relationships.
mixin HasRelationships {
  RelationDefinition hasOne<T extends KhademModel<T>>({
    required String foreignKey,
    required String relatedTable, required T Function() factory, String localKey = 'id',
  }) {
    return RelationDefinition<T>(
      type: RelationType.hasOne,
      localKey: localKey,
      foreignKey: foreignKey,
      relatedTable: relatedTable,
      factory: factory,
    );
  }

  RelationDefinition hasMany<T extends KhademModel<T>>({
    required String foreignKey,
    required String relatedTable, required T Function() factory, String localKey = 'id',
  }) {
    return RelationDefinition<T>(
      type: RelationType.hasMany,
      localKey: localKey,
      foreignKey: foreignKey,
      relatedTable: relatedTable,
      factory: factory,
    );
  }

  RelationDefinition belongsTo<T extends KhademModel<T>>({
    required String localKey,
    required String relatedTable, required T Function() factory, String foreignKey = 'id',
  }) {
    return RelationDefinition<T>(
      type: RelationType.belongsTo,
      localKey: localKey,
      foreignKey: foreignKey,
      relatedTable: relatedTable,
      factory: factory,
    );
  }

  RelationDefinition belongsToMany<T extends KhademModel<T>>({
    required String pivotTable,
    required String foreignPivotKey,
    required String relatedPivotKey,
    required String relatedTable,
    required String localKey,
    required T Function() factory,
  }) {
    return RelationDefinition<T>(
      type: RelationType.belongsToMany,
      localKey: localKey,
      foreignKey: 'id', // not used in belongsToMany loader
      relatedTable: relatedTable,
      factory: factory,
      pivotTable: pivotTable,
      foreignPivotKey: foreignPivotKey,
      relatedPivotKey: relatedPivotKey,
    );
  }

  RelationDefinition morphOne<T extends KhademModel<T>>({
    required String morphTypeField,
    required String morphIdField,
    required String relatedTable,
    required T Function() factory,
  }) {
    return RelationDefinition<T>(
      type: RelationType.morphOne,
      relatedTable: relatedTable,
      localKey: 'id',
      foreignKey: '', // not used
      factory: factory,
      morphTypeField: morphTypeField,
      morphIdField: morphIdField,
    );
  }

  RelationDefinition morphMany<T extends KhademModel<T>>({
    required String morphTypeField,
    required String morphIdField,
    required String relatedTable,
    required T Function() factory,
  }) {
    return RelationDefinition<T>(
      type: RelationType.morphMany,
      relatedTable: relatedTable,
      localKey: 'id',
      foreignKey: '', // not used
      factory: factory,
      morphTypeField: morphTypeField,
      morphIdField: morphIdField,
    );
  }

  RelationDefinition morphTo<T extends KhademModel<T>>({
    required String morphTypeField,
    required String morphIdField,
    required String relatedTable,
    required T Function() factory,
  }) {
    return RelationDefinition<T>(
      type: RelationType.morphTo,
      relatedTable: relatedTable,
      localKey: morphIdField,
      foreignKey: 'id',
      factory: factory,
      morphTypeField: morphTypeField,
      morphIdField: morphIdField,
    );
  }
}

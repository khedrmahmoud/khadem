import 'package:khadem/khadem.dart' show QueryBuilderInterface, Khadem;

import '../model_base/khadem_model.dart';
import 'relation_type.dart';
import 'relations/belongs_to.dart';
import 'relations/belongs_to_many.dart';
import 'relations/has_many.dart';
import 'relations/has_many_through.dart';
import 'relations/has_one.dart';
import 'relations/has_one_through.dart';
import 'relations/morph_many.dart';
import 'relations/morph_one.dart';
import 'relations/morph_to_many.dart';
import 'relations/morphed_by_many.dart';
import 'relations/relation.dart';

class RelationDefinition<T extends KhademModel<T>> {
  final RelationType type;
  final String relatedTable;
  final T Function() factory;

  /// The foreign key of the parent model.
  final String foreignKey;

  /// The local key of the parent model.
  final String localKey;

  /// The owner key of the related model (for BelongsTo).
  final String? ownerKey;

  /// The related key of the related model (for BelongsToMany).
  final String? relatedKey;

  final String? pivotTable;
  final String? foreignPivotKey;
  final String? relatedPivotKey;
  final String? morphTypeField;
  final String? morphIdField;
  final String? throughTable;
  final String? firstKey;
  final String? secondKey;
  final String? secondLocalKey;
  final Function(QueryBuilderInterface)? query;

  RelationDefinition({
    required this.type,
    required this.relatedTable,
    required this.localKey,
    required this.foreignKey,
    required this.factory,
    this.ownerKey,
    this.relatedKey,
    this.pivotTable,
    this.foreignPivotKey,
    this.relatedPivotKey,
    this.morphTypeField,
    this.morphIdField,
    this.throughTable,
    this.firstKey,
    this.secondKey,
    this.secondLocalKey,
    this.query,
  });

  Relation<T, KhademModel> toRelation(KhademModel parent, String relationName) {
    final q = Khadem.db
        .table(relatedTable, modelFactory: (data) => factory()..fromJson(data));
    if (query != null) {
      query!(q);
    }

    switch (type) {
      case RelationType.hasOne:
        return HasOne<T, KhademModel>(q, parent, factory, foreignKey, localKey);
      case RelationType.hasMany:
        return HasMany<T, KhademModel>(
          q,
          parent,
          factory,
          foreignKey,
          localKey,
        );
      case RelationType.belongsTo:
        return BelongsTo<T, KhademModel>(
          q,
          parent,
          factory,
          foreignKey,
          ownerKey ?? 'id',
          relationName,
        );
      case RelationType.belongsToMany:
        return BelongsToMany<T, KhademModel>(
          q,
          parent,
          factory,
          pivotTable!,
          foreignPivotKey!,
          relatedPivotKey!,
          localKey,
          relatedKey ?? 'id',
        );
      case RelationType.morphOne:
        return MorphOne<T, KhademModel>(
          q,
          parent,
          factory,
          morphTypeField!,
          morphIdField!,
          localKey,
        );
      case RelationType.morphMany:
        return MorphMany<T, KhademModel>(
          q,
          parent,
          factory,
          morphTypeField!,
          morphIdField!,
          localKey,
        );
      case RelationType.hasOneThrough:
        return HasOneThrough<T, KhademModel>(
          q,
          parent,
          factory,
          throughTable!,
          firstKey!,
          secondKey!,
          localKey,
          secondLocalKey!,
        );
      case RelationType.hasManyThrough:
        return HasManyThrough<T, KhademModel>(
          q,
          parent,
          factory,
          throughTable!,
          firstKey!,
          secondKey!,
          localKey,
          secondLocalKey!,
        );
      case RelationType.morphToMany:
        return MorphToMany<T, KhademModel>(
          q,
          parent,
          factory,
          pivotTable!,
          foreignPivotKey!,
          relatedPivotKey!,
          localKey,
          relatedKey ?? 'id',
          morphTypeField!,
          parent.table,
        );
      case RelationType.morphedByMany:
        return MorphedByMany<T, KhademModel>(
          q,
          parent,
          factory,
          pivotTable!,
          foreignPivotKey!,
          relatedPivotKey!,
          localKey,
          relatedKey ?? 'id',
          morphTypeField!,
          q.table,
        );
      default:
        throw UnimplementedError(
          'Relation type $type not implemented in toRelation',
        );
    }
  }
}

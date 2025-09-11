

import '../../../../../khadem_dart.dart';
import '../../orm/relation_meta.dart';

class EagerLoader {
  /// Parses a raw list of relation inputs into a list of [RelationMeta].
  static List<RelationMeta> parseRelations(List<dynamic> raw) {
    final result = <RelationMeta>[];

    for (final entry in raw) {
      if (entry is String) {
        final nestedSplit = entry.split('.');
        final mainPart = nestedSplit.first;
        final nested =
            nestedSplit.length > 1 ? [nestedSplit.sublist(1).join('.')] : [];

        final segments = mainPart.split(':');

        final key = segments.first;
        bool paginate = false;
        int? page;
        int? perPage;

        for (var segment in segments.skip(1)) {
          if (segment == 'paginated') {
            paginate = true;
          } else if (segment.startsWith('page=')) {
            page = int.tryParse(segment.replaceFirst('page=', ''));
          } else if (segment.startsWith('perPage=')) {
            perPage = int.tryParse(segment.replaceFirst('perPage=', ''));
          }
        }

        result.add(RelationMeta(
          key: key,
          paginate: paginate,
          page: page,
          perPage: perPage,
          nested: nested,
        ),);
      } else if (entry is Map<String, dynamic>) {
        for (final key in entry.keys) {
          final val = entry[key] as Map<String, dynamic>;
          result.add(RelationMeta(
            key: key,
            paginate: val['paginate'] ?? false,
            page: val['page'],
            perPage: val['perPage'],
            nested: val['with'] ?? [],
            query: val['query'],
          ),);
        }
      }
    }

    return result;
  }

  /// Loads relations based on parsed metadata.
  static Future<void> loadRelations(
      List<KhademModel> models, List<dynamic> relations,) async {
    if (models.isEmpty) return;

    final parsed = parseRelations(relations);
    for (final meta in parsed) {
      final def = models.first.relations[meta.key];
      if (def == null) continue;

      switch (def.type) {
        case RelationType.hasOne:
        case RelationType.hasMany:
          await _loadHasOneOrMany(
            models,
            def,
            meta.key,
            meta,
            nested: meta.nested,
          );
          break;

        case RelationType.belongsTo:
          await _loadBelongsTo(models, def, meta.key, meta, nested: meta.nested);
          break;

        case RelationType.belongsToMany:
          await _loadBelongsToMany(models, def, meta.key, meta, nested: meta.nested);
          break;

        case RelationType.morphOne:
        case RelationType.morphMany:
          await _loadMorph(models, def, meta.key, meta, nested: meta.nested);
          break;

        case RelationType.morphTo:
          // TODO: implement morphTo
          break;
      }
    }
  }

  static Future<void> _loadHasOneOrMany(
    List<KhademModel> parents,
    RelationDefinition def,
    String relationKey,
    RelationMeta meta, {
    List<dynamic> nested = const [],
  }) async {
    final parentIds =
        parents.map((p) => p.toJson()[def.localKey]).toSet().toList();
    if (parentIds.isEmpty) return;

    final placeholders = List.filled(parentIds.length, '?').join(', ');
    final query = Khadem.db
        .table<Map<String, dynamic>>(def.relatedTable)
        .whereRaw('${def.foreignKey} IN ($placeholders)', parentIds);

    // Apply query constraints if provided
    if (meta.query != null) {
      meta.query!(query);
    }
    if (def.query != null) {
      def.query!(query);
    }

    if (meta.paginate && meta.page != null && meta.perPage != null) {
      final pagination = await query.paginate(page: meta.page, perPage: meta.perPage);

      final related = pagination.data.map((r) {
        final model = def.factory();
        model.fromJson(r);
        return model;
      }).toList();

      if (nested.isNotEmpty) {
        await EagerLoader.loadRelations(related, nested);
      }

      final grouped = <dynamic, List<KhademModel>>{};
      for (var model in related) {
        final key = model.toJson()[def.foreignKey];
        grouped.putIfAbsent(key, () => []).add(model);
      }

      for (var parent in parents) {
        final id = parent.toJson()[def.localKey];
        parent.relation.set(relationKey, {
          'data': grouped[id] ?? [],
          'meta': {
            'page': pagination.currentPage,
            'perPage': pagination.perPage,
            'total': pagination.total,
            'lastPage': pagination.lastPage,
          },
        });
      }
    } else {
      final rows = await query.get();
      await _attachRelated(parents, def, relationKey, rows, nested);
    }
  }

  static Future<void> _attachRelated(
    List<KhademModel> parents,
    RelationDefinition def,
    String relationKey,
    List<Map<String, dynamic>> rows,
    List<dynamic> nested,
  ) async {
    final related = rows.map((r) {
      final model = def.factory();
      model.fromJson(r);
      return model;
    }).toList();

    if (nested.isNotEmpty) {
      await EagerLoader.loadRelations(related, nested);
    }

    final grouped = <dynamic, List<KhademModel>>{};
    for (var model in related) {
      final key = model.toJson()[def.foreignKey];
      grouped.putIfAbsent(key, () => []).add(model);
    }

    for (var parent in parents) {
      final id = parent.toJson()[def.localKey];
      if (def.type == RelationType.hasMany ||
          def.type == RelationType.morphMany) {
        parent.relation.set(relationKey, grouped[id] ?? []);
      } else {
        parent.relation.set(relationKey, grouped[id]?.first);
      }
    }
  }

  static Future<void> _loadBelongsTo(
    List<KhademModel> children,
    RelationDefinition def,
    String relationKey,
    RelationMeta meta, {
    List<dynamic> nested = const [],
  }) async {
    final foreignKeys =
        children.map((c) => c.toJson()[def.localKey]).toSet().toList();
    if (foreignKeys.isEmpty) return;

    final placeholders = List.filled(foreignKeys.length, '?').join(', ');
    final query = Khadem.db
        .table<Map<String, dynamic>>(def.relatedTable)
        .whereRaw('${def.foreignKey} IN ($placeholders)', foreignKeys);

    // Apply query constraints if provided
    if (meta.query != null) {
      meta.query!(query);
    }
    if (def.query != null) {
      def.query!(query);
    }

    final rows = await query.get();

    final related = rows.map((r) {
      final model = def.factory();
      model.fromJson(r);
      return model;
    }).toList();

    if (nested.isNotEmpty) {
      await EagerLoader.loadRelations(related, nested);
    }

    final lookup = {
      for (var model in related) model.toJson()[def.foreignKey]: model,
    };

    for (var child in children) {
      final key = child.toJson()[def.localKey];
      child.relation.set(relationKey, lookup[key]);
    }
  }

  static Future<void> _loadBelongsToMany(
    List<KhademModel> parents,
    RelationDefinition relation,
    String relationKey,
    RelationMeta meta, {
    List<dynamic> nested = const [],
  }) async {
    final parentIds =
        parents.map((p) => p.toJson()[relation.localKey]).toSet().toList();
    final placeholders = List.filled(parentIds.length, '?').join(', ');

    final pivotRows = await Khadem.db
        .table<Map<String, dynamic>>(relation.pivotTable!)
        .whereRaw('${relation.foreignPivotKey} IN ($placeholders)', parentIds)
        .get();

    final relatedIds =
        pivotRows.map((row) => row[relation.relatedPivotKey]).toSet().toList();

    final relatedRows = await Khadem.db
        .table<Map<String, dynamic>>(relation.relatedTable)
        .whereRaw('id IN (${List.filled(relatedIds.length, '?').join(', ')})',
            relatedIds,)
        .when(meta.query != null, (q) => meta.query!(q))
        .when(relation.query != null, (q) => relation.query!(q))
        .get();

    final relatedModels = relatedRows.map((row) {
      final model = relation.factory();
      model.fromJson(row);
      return model;
    }).toList();

    if (nested.isNotEmpty) {
      await EagerLoader.loadRelations(relatedModels, nested);
    }

    final grouped = <dynamic, List<KhademModel>>{};
    for (final row in pivotRows) {
      final parentId = row[relation.foreignPivotKey];
      final relatedId = row[relation.relatedPivotKey];

      final related =
          relatedModels.firstWhere((m) => m.toJson()['id'] == relatedId);
      grouped.putIfAbsent(parentId, () => []).add(related);
    }

    for (final parent in parents) {
      final id = parent.toJson()[relation.localKey];
      parent.relation.set(relationKey, grouped[id] ?? []);
    }
  }

  static Future<void> _loadMorph(
    List<KhademModel> parents,
    RelationDefinition relation,
    String relationKey,
    RelationMeta meta, {
    List<dynamic> nested = const [],
  }) async {
    final ids =
        parents.map((p) => p.toJson()[relation.morphIdField!]).toSet().toList();
    final type = parents.first.runtimeType.toString().toLowerCase();
    final placeholders = List.filled(ids.length, '?').join(', ');

    final rows = await Khadem.db
        .table<Map<String, dynamic>>(relation.relatedTable)
        .whereRaw(
      '${relation.morphIdField} IN ($placeholders) AND ${relation.morphTypeField} = ?',
      [...ids, type],
    ).when(meta.query != null, (q) => meta.query!(q))
    .when(relation.query != null, (q) => relation.query!(q))
    .get();

    final relatedModels = rows.map((r) {
      final model = relation.factory();
      model.fromJson(r);
      return model;
    }).toList();

    if (nested.isNotEmpty) {
      await EagerLoader.loadRelations(relatedModels, nested);
    }

    final grouped = <dynamic, List<KhademModel>>{};
    for (var model in relatedModels) {
      final key = model.toJson()[relation.morphIdField];
      grouped.putIfAbsent(key, () => []).add(model);
    }

    for (var parent in parents) {
      final id = parent.toJson()[relation.morphIdField];
      if (relation.type == RelationType.morphMany) {
        parent.relation.set(relationKey, grouped[id] ?? []);
      } else {
        parent.relation.set(relationKey, grouped[id]?.first);
      }
    }
  }
}


// import '../../../core/core.dart';
// import '../../../core/database/orm/relation_meta.dart';
// import '../../../khadem.dart';
// import '../../../types/relation_type.dart';

// class EagerLoader {
//   List<RelationMeta> parseRelations(List<dynamic> raw) {
//     final result = <RelationMeta>[];

//     for (final entry in raw) {
//       if (entry is String) {
//         final isPaginated = entry.contains(':paginated');
//         final parts = entry.replaceAll(':paginated', '').split('.');
//         final key = parts.first;
//         final nested = parts.length > 1 ? [parts.sublist(1).join('.')] : [];

//         result.add(RelationMeta(
//           key: key,
//           paginate: isPaginated,
//           nested: nested,
//         ));
//       } else if (entry is Map<String, dynamic>) {
//         for (final key in entry.keys) {
//           final val = entry[key] as Map<String, dynamic>;
//           result.add(RelationMeta(
//             key: key,
//             paginate: val['paginate'] ?? false,
//             page: val['page'],
//             perPage: val['perPage'],
//             nested: val['with'] ?? [],
//           ));
//         }
//       }
//     }

//     return result;
//   }

//   static Future<void> loadRelations(
//       List<KhademModel> models, List<String> relations) async {
//     if (models.isEmpty) return;

//     for (final relationKey in relations) {
//       final def = models.first.relations[relationKey];
//       if (def == null) continue;

//       switch (def.type) {
//         case RelationType.hasOne:
//         case RelationType.hasMany:
//           await _loadHasOneOrMany(models, def, relationKey);
//           break;
//         case RelationType.belongsTo:
//           await _loadBelongsTo(models, def, relationKey);
//           break;
//         case RelationType.belongsToMany:
//           await _loadBelongsToMany(models, def, relationKey);
//           break;
//         case RelationType.morphOne:
//         case RelationType.morphMany:
//           await _loadMorph(models, def, relationKey);
//           break;
//         case RelationType.morphTo:
//           // await _loadMorphTo(models.first, def, relationKey);
//           // TODO: implement morphTo
//           break;
//       }
//     }
//   }

//   static Future<void> _loadHasOneOrMany(List<KhademModel> parents,
//       RelationDefinition def, String relationKey) async {
//     final parentIds =
//         parents.map((p) => p.toJson()[def.localKey]).toSet().toList();
//     if (parentIds.isEmpty) return;

//     final placeholders = List.filled(parentIds.length, '?').join(', ');
//     final rows = await Khadem.db
//         .table<Map<String, dynamic>>(def.relatedTable)
//         .whereRaw('${def.foreignKey} IN ($placeholders)', parentIds)
//         .get();

//     final related = rows.map((r) {
//       final model = def.factory();
//       model.fromJson(r);
//       return model;
//     }).toList();

//     final grouped = <dynamic, List<KhademModel>>{};
//     for (var model in related) {
//       final key = model.toJson()[def.foreignKey];
//       grouped.putIfAbsent(key, () => []).add(model);
//     }
//     for (var parent in parents) {
//       final id = parent.toJson()[def.localKey];
//       if (def.type == RelationType.hasMany) {
//         parent.setRelation(relationKey, grouped[id] ?? []);
//       } else {
//         parent.setRelation(relationKey, grouped[id]?.first);
//       }
//     }
//   }

//   static Future<void> _loadBelongsTo(List<KhademModel> children,
//       RelationDefinition def, String relationKey) async {
//     final foreignKeys =
//         children.map((c) => c.toJson()[def.localKey]).toSet().toList();
//     if (foreignKeys.isEmpty) return;

//     final placeholders = List.filled(foreignKeys.length, '?').join(', ');
//     final rows = await Khadem.db
//         .table<Map<String, dynamic>>(def.relatedTable)
//         .whereRaw('${def.foreignKey} IN ($placeholders)', foreignKeys)
//         .get();

//     final related = rows.map((r) {
//       final model = def.factory();
//       model.fromJson(r);
//       return model;
//     }).toList();

//     final lookup = {
//       for (var model in related) model.toJson()[def.foreignKey]: model
//     };

//     for (var child in children) {
//       final key = child.toJson()[def.localKey];
//       child.setRelation(relationKey, lookup[key]);
//     }
//   }

//   static Future<void> _loadBelongsToMany(
//     List<KhademModel> parents,
//     RelationDefinition relation,
//     String relationKey,
//   ) async {
//     final parentIds =
//         parents.map((p) => p.toJson()[relation.localKey]).toSet().toList();
//     final placeholders = List.filled(parentIds.length, '?').join(', ');

//     final rows = await Khadem.db
//         .table<Map<String, dynamic>>(relation.relatedTable)
//         .whereRaw(
//           'id IN (SELECT ${relation.relatedPivotKey} FROM ${relation.pivotTable} WHERE ${relation.foreignPivotKey} IN ($placeholders))',
//           parentIds,
//         )
//         .get();

//     final related = rows.map((r) {
//       final model = relation.factory();
//       model.fromJson(r);
//       return model;
//     }).toList();

//     // now group related by foreignPivotKey
//     final pivotRows = await Khadem.db
//         .table<Map<String, dynamic>>(relation.pivotTable!)
//         .whereRaw('${relation.foreignPivotKey} IN ($placeholders)', parentIds)
//         .get();

//     final pivotMap = <dynamic, List<dynamic>>{};
//     for (final row in pivotRows) {
//       final parentId = row[relation.foreignPivotKey];
//       final relatedId = row[relation.relatedPivotKey];
//       pivotMap.putIfAbsent(parentId, () => []).add(relatedId);
//     }

//     for (final parent in parents) {
//       final id = parent.toJson()[relation.localKey];
//       final relatedIds = pivotMap[id] ?? [];
//       final items =
//           related.where((r) => relatedIds.contains(r.toJson()['id'])).toList();
//       parent.setRelation(relationKey, items);
//     }
//   }

//   static Future<void> _loadMorph(List<KhademModel> parents,
//       RelationDefinition relation, String relationKey) async {
//     final ids =
//         parents.map((p) => p.toJson()[relation.morphIdField!]).toSet().toList();
//     final type = parents.first.runtimeType.toString().toLowerCase();
//     final placeholders = List.filled(ids.length, '?').join(', ');

//     final rows = await Khadem.db
//         .table<Map<String, dynamic>>(relation.relatedTable)
//         .whereRaw(
//             '${relation.morphIdField} IN ($placeholders) AND ${relation.morphTypeField} = ?',
//             [...ids, type]).get();

//     final relatedModels = rows.map((r) {
//       final model = relation.factory();
//       model.fromJson(r);
//       return model;
//     }).toList();

//     final grouped = <dynamic, List<KhademModel>>{};
//     for (var model in relatedModels) {
//       final key = model.toJson()[relation.morphIdField];
//       grouped.putIfAbsent(key, () => []).add(model);
//     }

//     for (var parent in parents) {
//       final id = parent.toJson()[relation.morphIdField];
//       if (relation.type == RelationType.morphOne) {
//         parent.setRelation(relationKey, grouped[id]?.first);
//       } else {
//         parent.setRelation(relationKey, grouped[id] ?? []);
//       }
//     }
//   }
// }
import 'package:khadem/khadem.dart';

/// A utility class for eager loading database relations in the Khadem ORM.
///
/// This class provides functionality to load related models efficiently by parsing
/// relation specifications and executing optimized database queries to fetch
/// related data in batches rather than individual queries.
///
/// Supports various relation types including:
/// - hasOne/hasMany (one-to-one, one-to-many)
/// - belongsTo (many-to-one)
/// - belongsToMany (many-to-many with pivot table)
/// - morphOne/morphMany (polymorphic relations)
class EagerLoader {
  /// Parses a raw list of relation inputs into a list of [RelationMeta].
  ///
  /// Supports multiple input formats:
  /// - Simple strings: `'posts'`, `'user:paginated'`, `'comments:page=1:perPage=10'`
  /// - Nested relations: `'user.posts'`
  /// - Complex objects: `{'posts': {'paginate': true, 'page': 1, 'perPage': 10, 'with': ['comments']}}`
  ///
  /// Parameters:
  /// - [raw]: List of relation specifications (strings or maps)
  ///
  /// Returns: List of parsed [RelationMeta] objects containing relation metadata
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

        result.add(
          RelationMeta(
            key: key,
            paginate: paginate,
            page: page,
            perPage: perPage,
            nested: nested,
          ),
        );
      } else if (entry is Map<String, dynamic>) {
        for (final key in entry.keys) {
          final val = entry[key] as Map<String, dynamic>;
          result.add(
            RelationMeta(
              key: key,
              paginate: val['paginate'] ?? false,
              page: val['page'],
              perPage: val['perPage'],
              nested: val['with'] ?? [],
              query: val['query'],
            ),
          );
        }
      }
    }

    return result;
  }

  /// Loads relations based on parsed metadata.
  ///
  /// This is the main entry point for eager loading. It processes each relation
  /// specification and delegates to the appropriate loading method based on
  /// the relation type defined in the model's relation definitions.
  ///
  /// Parameters:
  /// - [models]: List of parent models to load relations for
  /// - [relations]: List of relation specifications (passed to [parseRelations])
  ///
  /// The loaded relations are attached to each model via the model's relation property.
  static Future<void> loadRelations(
    List<KhademModel> models,
    List<dynamic> relations,
  ) async {
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
          await _loadBelongsTo(
            models,
            def,
            meta.key,
            meta,
            nested: meta.nested,
          );
          break;

        case RelationType.belongsToMany:
          await _loadBelongsToMany(
            models,
            def,
            meta.key,
            meta,
            nested: meta.nested,
          );
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

  /// Loads hasOne or hasMany relations for the given parent models.
  ///
  /// This method performs a single optimized query to fetch all related records
  /// for multiple parent models, then groups and attaches them appropriately.
  ///
  /// Supports pagination when [meta.paginate] is true, returning both data and
  /// pagination metadata in the relation result.
  ///
  /// Parameters:
  /// - [parents]: Parent models to load relations for
  /// - [def]: Relation definition containing table and key information
  /// - [relationKey]: The key to store the loaded relation under
  /// - [meta]: Parsed relation metadata (pagination, constraints, etc.)
  /// - [nested]: List of nested relations to load on the related models
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
      final pagination =
          await query.paginate(page: meta.page, perPage: meta.perPage);

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

  /// Helper method to attach related models to their parent models.
  ///
  /// Groups related models by their foreign key, loads any nested relations,
  /// and attaches the appropriate data structure based on relation type:
  /// - hasMany/morphMany: List of related models
  /// - hasOne/morphOne: Single related model or null
  ///
  /// Parameters:
  /// - [parents]: Parent models to attach relations to
  /// - [def]: Relation definition
  /// - [relationKey]: Key to store the relation under
  /// - [rows]: Raw database rows to convert to models
  /// - [nested]: Nested relations to load on related models
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

  /// Loads belongsTo relations for the given child models.
  ///
  /// Performs a single query to fetch all parent records for multiple child models,
  /// then creates a lookup table to efficiently attach the correct parent to each child.
  ///
  /// Parameters:
  /// - [children]: Child models that belong to parent records
  /// - [def]: Relation definition containing table and key information
  /// - [relationKey]: The key to store the loaded relation under
  /// - [meta]: Parsed relation metadata (constraints, etc.)
  /// - [nested]: List of nested relations to load on the parent models
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

  /// Loads belongsToMany (many-to-many) relations using a pivot table.
  ///
  /// This method handles the complex case of many-to-many relationships by:
  /// 1. Querying the pivot table to get related IDs
  /// 2. Fetching the actual related records
  /// 3. Grouping results by parent ID for attachment
  ///
  /// Parameters:
  /// - [parents]: Parent models to load relations for
  /// - [relation]: Relation definition (must include pivot table info)
  /// - [relationKey]: The key to store the loaded relation under
  /// - [meta]: Parsed relation metadata (constraints, etc.)
  /// - [nested]: List of nested relations to load on the related models
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
        .whereRaw(
          'id IN (${List.filled(relatedIds.length, '?').join(', ')})',
          relatedIds,
        )
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

  /// Loads polymorphic (morphOne/morphMany) relations.
  ///
  /// Polymorphic relations allow a model to belong to multiple other model types.
  /// This method queries based on both the morph ID and morph type fields to
  /// ensure only related records of the correct type are loaded.
  ///
  /// Parameters:
  /// - [parents]: Parent models to load relations for
  /// - [relation]: Relation definition with morph field information
  /// - [relationKey]: The key to store the loaded relation under
  /// - [meta]: Parsed relation metadata (constraints, etc.)
  /// - [nested]: List of nested relations to load on the related models
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
        )
        .when(meta.query != null, (q) => meta.query!(q))
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

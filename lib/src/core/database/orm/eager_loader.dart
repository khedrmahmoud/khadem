import '../model_base/khadem_model.dart';
import 'relation_meta.dart';
import 'with.dart';

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
    final Map<String, RelationMeta> grouped = {};

    void addOrMergeMeta(RelationMeta newMeta) {
      if (grouped.containsKey(newMeta.key)) {
        final existing = grouped[newMeta.key]!;
        existing.nested.addAll(newMeta.nested);
        // We could also merge pagination settings if needed, but for now we keep the existing or override.
        // We'll keep the existing logic simple by just updating pagination if it's explicitly set in newMeta.
        grouped[newMeta.key] = RelationMeta(
          key: existing.key,
          paginate: newMeta.paginate || existing.paginate,
          page: newMeta.page ?? existing.page,
          perPage: newMeta.perPage ?? existing.perPage,
          nested: existing.nested.toSet().toList(), // unique
          query: newMeta.query ?? existing.query,
        );
      } else {
        grouped[newMeta.key] = newMeta;
      }
    }

    for (final entry in raw) {
      if (entry is String) {
        final nestedSplit = entry.split('.');
        final mainPart = nestedSplit.first;
        final nested = nestedSplit.length > 1
            ? [nestedSplit.sublist(1).join('.')]
            : [];

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

        addOrMergeMeta(
          RelationMeta(
            key: key,
            paginate: paginate,
            page: page,
            perPage: perPage,
            nested: nested,
          ),
        );
      } else if (entry is Map || entry is Map<String, dynamic>) {
        if (entry is Map) {
          entry.forEach((key, val) {
            if (val is Map) {
              final nested = val['with'] ?? [];
              final nestedList = nested is List ? nested : [nested];

              addOrMergeMeta(
                RelationMeta(
                  key: key.toString(),
                  paginate: val['paginate'] ?? false,
                  page: val['page'],
                  perPage: val['perPage'],
                  nested: List<dynamic>.from(nestedList),
                  query: val['query'],
                ),
              );
            }
          });
        }
      } else if (entry is With) {
        addOrMergeMeta(
          RelationMeta(
            key: entry.relation,
            paginate: entry.paginate,
            page: entry.page,
            perPage: entry.perPage,
            nested: List<dynamic>.from(entry.nested),
            query: entry.query,
          ),
        );
      }
    }

    return grouped.values.toList();
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
      final relationName = meta.key;
      final firstModel = models.first;

      try {
        final relationObj = (firstModel as HasRelations).relation(relationName);

        relationObj.addEagerConstraints(models);

        if (meta.query != null) {
          meta.query!(relationObj.getQuery());
        }

        // Execute query
        final results = await relationObj.getQuery().get();

        // Match results
        relationObj.match(models, results, relationName);

        // Handle nested relations
        if (meta.nested.isNotEmpty) {
          await loadRelations(results.cast<KhademModel>(), meta.nested);
        }
      } catch (e) {
        rethrow;
      }
    }
  }
}

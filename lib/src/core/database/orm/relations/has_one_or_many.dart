import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';
import 'relation.dart';

abstract class HasOneOrMany<Related extends KhademModel<Related>, Parent>
    extends Relation<Related, Parent> {
  final String foreignKey;
  final String localKey;

  HasOneOrMany(
    super.query,
    super.parent,
    super.relatedFactory,
    this.foreignKey,
    this.localKey,
  );

  @override
  void addConstraints() {
    if ((parent as KhademModel).getAttribute(localKey) != null) {
      query.where(
        foreignKey,
        '=',
        (parent as KhademModel).getAttribute(localKey),
      );
    }
  }

  @override
  void addEagerConstraints(List<KhademModel> models) {
    final keys = models
        .map((model) => model.getAttribute(localKey))
        .where((key) => key != null)
        .toSet()
        .toList();
    query.whereIn(foreignKey, keys);
  }

  @override
  QueryBuilderInterface<Related> getRelationExistenceQuery(
    QueryBuilderInterface<Related> query,
    QueryBuilderInterface<Parent> parentQuery, [
    List<String> columns = const ['*'],
  ]) {
    final relatedTable = query.table;
    final parentTable = parentQuery.table;

    return query
        .select(columns)
        .whereColumn(
          '$relatedTable.$foreignKey',
          '=',
          '$parentTable.$localKey',
        );
  }

  /// Match the eagerly loaded results to their parents.
  List<KhademModel> matchOneOrMany(
    List<KhademModel> models,
    List<Related> results,
    String relation,
    String type,
  ) {
    final dictionary = <dynamic, List<Related>>{};

    for (final result in results) {
      final key = result.getAttribute(foreignKey);
      if (key != null) {
        if (!dictionary.containsKey(key)) {
          dictionary[key] = [];
        }
        dictionary[key]!.add(result);
      }
    }

    for (final model in models) {
      final key = model.getAttribute(localKey);
      if (dictionary.containsKey(key)) {
        final value = dictionary[key]!;
        if (type == 'one') {
          model.setRelation(relation, value.isNotEmpty ? value.first : null);
        } else {
          model.setRelation(relation, value);
        }
      } else {
        if (type == 'one') {
          model.setRelation(relation, null);
        } else {
          model.setRelation(relation, <Related>[]);
        }
      }
    }

    return models;
  }
}

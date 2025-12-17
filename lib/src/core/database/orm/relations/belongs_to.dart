import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';
import 'relation.dart';

class BelongsTo<Related extends KhademModel<Related>, Parent>
    extends Relation<Related, Parent> {
  final String foreignKey;
  final String ownerKey;
  final String relationName;

  BelongsTo(
    super.query,
    super.parent,
    super.relatedFactory,
    this.foreignKey,
    this.ownerKey,
    this.relationName,
  );

  @override
  void addConstraints() {
    if ((parent as KhademModel).getAttribute(foreignKey) != null) {
      query.where(
          ownerKey, '=', (parent as KhademModel).getAttribute(foreignKey),);
    }
  }

  @override
  void addEagerConstraints(List<Parent> models) {
    final keys = models
        .map((model) => (model as KhademModel).getAttribute(foreignKey))
        .where((key) => key != null)
        .toSet()
        .toList();
    query.whereIn(ownerKey, keys);
  }

  @override
  QueryBuilderInterface<Related> getRelationExistenceQuery(
      QueryBuilderInterface<Related> query,
      QueryBuilderInterface<Parent> parentQuery,
      [List<String> columns = const ['*'],]) {
    final relatedTable = query.table;
    final parentTable = parentQuery.table;

    return query.select(columns).whereColumn(
          '$relatedTable.$ownerKey',
          '=',
          '$parentTable.$foreignKey',
        );
  }

  @override
  Future<Related?> getResults() async {
    return query.first();
  }

  @override
  List<Parent> initRelation(List<Parent> models, String relation) {
    for (final model in models) {
      (model as KhademModel).setRelation(relation, null);
    }
    return models;
  }

  @override
  List<Parent> match(
      List<Parent> models, List<Related> results, String relation,) {
    final dictionary = <dynamic, Related>{};

    for (final result in results) {
      final key = result.getAttribute(ownerKey);
      if (key != null) {
        dictionary[key] = result;
      }
    }

    for (final model in models) {
      final key = (model as KhademModel).getAttribute(foreignKey);
      if (dictionary.containsKey(key)) {
        (model as KhademModel).setRelation(relation, dictionary[key]);
      }
    }

    return models;
  }
}

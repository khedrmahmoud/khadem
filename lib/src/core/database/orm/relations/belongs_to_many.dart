import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';
import 'relation.dart';

class BelongsToMany<Related extends KhademModel<Related>, Parent>
    extends Relation<Related, Parent> {
  final String table;
  final String foreignPivotKey;
  final String relatedPivotKey;
  final String parentKey;
  final String relatedKey;

  BelongsToMany(
    super.query,
    super.parent,
    super.relatedFactory,
    this.table,
    this.foreignPivotKey,
    this.relatedPivotKey,
    this.parentKey,
    this.relatedKey,
  );

  @override
  void addConstraints() {
    _performJoin();
    if ((parent as KhademModel).getAttribute(parentKey) != null) {
      query.where(
        '$table.$foreignPivotKey',
        '=',
        (parent as KhademModel).getAttribute(parentKey),
      );
    }
  }

  void _performJoin([QueryBuilderInterface<Related>? q]) {
    final queryToJoin = q ?? query;
    final relatedTable = queryToJoin.table;

    queryToJoin.join(
      table,
      '$relatedTable.$relatedKey',
      '=',
      '$table.$relatedPivotKey',
    );
  }

  @override
  void addEagerConstraints(List<KhademModel> models) {
    _performJoin();
    final keys = models
        .map((model) => model.getAttribute(parentKey))
        .where((key) => key != null)
        .toSet()
        .toList();
    query.whereIn('$table.$foreignPivotKey', keys);
  }

  @override
  QueryBuilderInterface<Related> getRelationExistenceQuery(
    QueryBuilderInterface<Related> query,
    QueryBuilderInterface<Parent> parentQuery, [
    List<String> columns = const ['*'],
  ]) {
    _performJoin(query);

    final parentTable = parentQuery.table;

    return query.select(columns).whereColumn(
          '$table.$foreignPivotKey',
          '=',
          '$parentTable.$parentKey',
        );
  }

  @override
  Future<List<Related>> getResults() async {
    return query.get();
  }

  @override
  List<KhademModel> initRelation(List<KhademModel> models, String relation) {
    for (final model in models) {
      model.setRelation(relation, <Related>[]);
    }
    return models;
  }

  @override
  List<KhademModel> match(
    List<KhademModel> models,
    List<Related> results,
    String relation,
  ) {
    // This is tricky because we need the pivot data to match.
    // In a real implementation, we would select the pivot columns as well.
    // For now, we assume the pivot data is available or we re-query (which is inefficient).
    // A better way is to select pivot fields in the query.

    // TODO: Implement proper matching with pivot data.
    // For now, this is a placeholder that might not work correctly without pivot data in results.
    return models;
  }
}

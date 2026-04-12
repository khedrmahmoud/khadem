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

  void _addPivotSelects() {
    if (query.columns.isEmpty ||
        (query.columns.length == 1 && query.columns.first == '*')) {
      query.select(['${query.table}.*']);
    }
    query.selectRaw('$table.$foreignPivotKey as khadem_pivot_foreign_key');
    query.selectRaw('$table.$relatedPivotKey as khadem_pivot_related_key');
  }

  @override
  void addConstraints() {
    _performJoin();
    _addPivotSelects();
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
    _addPivotSelects();
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

    return query
        .select(columns)
        .whereColumn('$table.$foreignPivotKey', '=', '$parentTable.$parentKey');
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
    final dictionary = <dynamic, List<Related>>{};

    for (final result in results) {
      final key = result.getAttribute('khadem_pivot_foreign_key');
      if (key != null) {
        (dictionary[key] ??= <Related>[]).add(result);
      }
    }

    for (final model in models) {
      final key = model.getAttribute(parentKey);
      if (dictionary.containsKey(key)) {
        model.setRelation(relation, dictionary[key]);
      } else {
        model.setRelation(relation, <Related>[]);
      }
    }

    return models;
  }
}

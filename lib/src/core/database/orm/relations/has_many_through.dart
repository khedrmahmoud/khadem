import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';
import 'relation.dart';

class HasManyThrough<Related extends KhademModel<Related>, Parent>
    extends Relation<Related, Parent> {
  final String throughTable;
  final String firstKey;
  final String secondKey;
  final String localKey;
  final String secondLocalKey;

  HasManyThrough(
    super.query,
    super.parent,
    super.relatedFactory,
    this.throughTable,
    this.firstKey,
    this.secondKey,
    this.localKey,
    this.secondLocalKey,
  );

  @override
  void addConstraints() {
    final localValue = (parent as KhademModel).getAttribute(localKey);
    _performJoin();
    if (localValue != null) {
      query.where('$throughTable.$firstKey', '=', localValue);
    }
  }

  void _performJoin([QueryBuilderInterface<Related>? q]) {
    final queryToJoin = q ?? query;
    final relatedTable = queryToJoin.table;

    queryToJoin.join(
      throughTable,
      '$throughTable.$secondLocalKey',
      '=',
      '$relatedTable.$secondKey',
    );
  }

  @override
  void addEagerConstraints(List<KhademModel> models) {
    _performJoin();
    final keys = models
        .map((model) => model.getAttribute(localKey))
        .where((key) => key != null)
        .toSet()
        .toList();
    query.whereIn('$throughTable.$firstKey', keys);
    query.select(['${query.table}.*']);
    query.selectRaw('$throughTable.$firstKey as khadem_through_key');
  }

  @override
  QueryBuilderInterface<Related> getRelationExistenceQuery(
      QueryBuilderInterface<Related> query,
      QueryBuilderInterface<Parent> parentQuery,
      [List<String> columns = const ['*'],]) {
    _performJoin(query);

    final parentTable = parentQuery.table;

    return query.select(columns).whereColumn(
          '$parentTable.$localKey',
          '=',
          '$throughTable.$firstKey',
        );
  }

  @override
  Future<dynamic> getResults() async {
    if (query.columns.isEmpty ||
        (query.columns.length == 1 && query.columns.first == '*')) {
      query.select(['${query.table}.*']);
    }
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
      List<KhademModel> models, List<Related> results, String relation,) {
    final dictionary = <dynamic, List<Related>>{};

    for (final result in results) {
      final key = result.getAttribute('khadem_through_key');
      if (key != null) {
        if (!dictionary.containsKey(key)) {
          dictionary[key] = [];
        }
        dictionary[key]!.add(result);
      }
      // Clean up the temporary attribute
      // result.unsetAttribute('khadem_through_key'); // If such method exists
    }

    for (final model in models) {
      final key = model.getAttribute(localKey);
      if (dictionary.containsKey(key)) {
        model.setRelation(relation, dictionary[key]);
      }
    }

    return models;
  }
}

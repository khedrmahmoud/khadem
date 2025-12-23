import '../../model_base/khadem_model.dart';
import 'has_many_through.dart';

class HasOneThrough<Related extends KhademModel<Related>, Parent>
    extends HasManyThrough<Related, Parent> {
  HasOneThrough(
    super.query,
    super.parent,
    super.relatedFactory,
    super.throughTable,
    super.firstKey,
    super.secondKey,
    super.localKey,
    super.secondLocalKey,
  );

  @override
  Future<Related?> getResults() async {
    if (query.columns.isEmpty ||
        (query.columns.length == 1 && query.columns.first == '*')) {
      query.select(['${query.table}.*']);
    }
    return query.first();
  }

  @override
  List<KhademModel> initRelation(List<KhademModel> models, String relation) {
    for (final model in models) {
      model.setRelation(relation, null);
    }
    return models;
  }

  @override
  List<KhademModel> match(
      List<KhademModel> models, List<Related> results, String relation,) {
    final dictionary = <dynamic, Related>{};

    for (final result in results) {
      final key = result.getAttribute('khadem_through_key');
      if (key != null) {
        dictionary[key] = result;
      }
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

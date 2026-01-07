import '../../model_base/khadem_model.dart';
import 'has_one_or_many.dart';

class HasMany<Related extends KhademModel<Related>, Parent>
    extends HasOneOrMany<Related, Parent> {
  HasMany(
    super.query,
    super.parent,
    super.relatedFactory,
    super.foreignKey,
    super.localKey,
  );

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
    return matchOneOrMany(models, results, relation, 'many');
  }
}

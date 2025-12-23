import '../../model_base/khadem_model.dart';
import 'has_one_or_many.dart';

class HasOne<Related extends KhademModel<Related>, Parent>
    extends HasOneOrMany<Related, Parent> {
  HasOne(
    super.query,
    super.parent,
    super.relatedFactory,
    super.foreignKey,
    super.localKey,
  );

  @override
  Future<Related?> getResults() async {
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
    return matchOneOrMany(models, results, relation, 'one');
  }
}

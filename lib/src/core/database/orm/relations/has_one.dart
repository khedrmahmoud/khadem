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
  List<Parent> initRelation(List<Parent> models, String relation) {
    for (final model in models) {
      (model as KhademModel).setRelation(relation, null);
    }
    return models;
  }

  @override
  List<Parent> match(
      List<Parent> models, List<Related> results, String relation,) {
    return matchOneOrMany(models, results, relation, 'one');
  }
}

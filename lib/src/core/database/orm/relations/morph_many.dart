import '../../model_base/khadem_model.dart';
import 'morph_one_or_many.dart';

class MorphMany<Related extends KhademModel<Related>, Parent>
    extends MorphOneOrMany<Related, Parent> {
  MorphMany(
    super.query,
    super.parent,
    super.relatedFactory,
    super.morphTypeField,
    super.morphIdField,
    super.localKey,
  );

  @override
  Future<List<Related>> getResults() async {
    return query.get();
  }

  @override
  List<Parent> initRelation(List<Parent> models, String relation) {
    for (final model in models) {
      (model as KhademModel).setRelation(relation, <Related>[]);
    }
    return models;
  }

  @override
  List<Parent> match(
      List<Parent> models, List<Related> results, String relation,) {
    return matchOneOrMany(models, results, relation, 'many');
  }
}

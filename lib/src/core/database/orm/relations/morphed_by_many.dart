import '../../model_base/khadem_model.dart';
import 'morph_to_many.dart';

class MorphedByMany<Related extends KhademModel<Related>, Parent>
    extends MorphToMany<Related, Parent> {
  MorphedByMany(
    super.query,
    super.parent,
    super.relatedFactory,
    super.table,
    super.foreignPivotKey,
    super.relatedPivotKey,
    super.parentKey,
    super.relatedKey,
    super.morphTypeField,
    super.morphClass,
  ) : super(
          inverse: true,
        );
}

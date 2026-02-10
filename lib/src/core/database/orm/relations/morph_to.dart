import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';
import 'belongs_to.dart';

/// A polymorphic inverse relation (fixed target type).
///
/// This behaves like a `belongsTo`, but only applies constraints when the
/// parent's morph type matches the expected [morphClass].
class MorphTo<Related extends KhademModel<Related>, Parent>
    extends BelongsTo<Related, Parent> {
  final String morphTypeField;
  final String morphIdField;
  final String morphClass;

  MorphTo(
    QueryBuilderInterface<Related> query,
    Parent parent,
    Related Function() relatedFactory,
    this.morphTypeField,
    this.morphIdField,
    this.morphClass,
    String ownerKey,
    String relationName,
  ) : super(
          query,
          parent,
          relatedFactory,
          morphIdField,
          ownerKey,
          relationName,
        );

  bool _matchesMorphType(KhademModel model) {
    return model.getAttribute(morphTypeField) == morphClass;
  }

  @override
  void addConstraints() {
    final parentModel = parent as KhademModel;
    if (!_matchesMorphType(parentModel)) {
      query.whereRaw('1 = 0');
      return;
    }
    super.addConstraints();
  }

  @override
  void addEagerConstraints(List<KhademModel> models) {
    final keys = models
        .where(_matchesMorphType)
        .map((model) => model.getAttribute(morphIdField))
        .where((key) => key != null)
        .toSet()
        .toList();

    if (keys.isEmpty) {
      query.whereRaw('1 = 0');
      return;
    }

    query.whereIn(ownerKey, keys);
  }

  @override
  QueryBuilderInterface<Related> getRelationExistenceQuery(
    QueryBuilderInterface<Related> query,
    QueryBuilderInterface<Parent> parentQuery, [
    List<String> columns = const ['*'],
  ]) {
    final q = super.getRelationExistenceQuery(query, parentQuery, columns);
    final parentTable = parentQuery.table;
    return q.where('$parentTable.$morphTypeField', '=', morphClass);
  }
}

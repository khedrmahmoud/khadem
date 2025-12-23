import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';
import 'belongs_to_many.dart';

class MorphToMany<Related extends KhademModel<Related>, Parent>
    extends BelongsToMany<Related, Parent> {
  final String morphTypeField;
  final String morphClass;
  final bool inverse;

  MorphToMany(
    super.query,
    super.parent,
    super.relatedFactory,
    super.table,
    super.foreignPivotKey,
    super.relatedPivotKey,
    super.parentKey,
    super.relatedKey,
    this.morphTypeField,
    this.morphClass, {
    this.inverse = false,
  });

  @override
  void addConstraints() {
    super.addConstraints();
    query.where('$table.$morphTypeField', '=', morphClass);
  }

  @override
  void addEagerConstraints(List<KhademModel> models) {
    super.addEagerConstraints(models);
    query.where('$table.$morphTypeField', '=', morphClass);
  }

  @override
  QueryBuilderInterface<Related> getRelationExistenceQuery(
      QueryBuilderInterface<Related> query,
      QueryBuilderInterface<Parent> parentQuery,
      [List<String> columns = const ['*'],]) {
    final q = super.getRelationExistenceQuery(query, parentQuery, columns);
    return q.where('$table.$morphTypeField', '=', morphClass);
  }
}

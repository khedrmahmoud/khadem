import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';
import 'has_one_or_many.dart';

abstract class MorphOneOrMany<Related extends KhademModel<Related>, Parent>
    extends HasOneOrMany<Related, Parent> {
  final String morphType;
  final String morphTypeField;
  final String morphIdField;

  MorphOneOrMany(
    QueryBuilderInterface<Related> query,
    Parent parent,
    Related Function() relatedFactory,
    this.morphTypeField,
    this.morphIdField,
    String localKey,
  )   : morphType = parent.runtimeType.toString(),
        super(query, parent, relatedFactory, morphIdField, localKey);

  @override
  void addConstraints() {
    super.addConstraints();
    query.where(morphTypeField, '=', morphType);
  }

  @override
  void addEagerConstraints(List<KhademModel> models) {
    super.addEagerConstraints(models);
    query.where(morphTypeField, '=', morphType);
  }

  @override
  QueryBuilderInterface<Related> getRelationExistenceQuery(
      QueryBuilderInterface<Related> query,
      QueryBuilderInterface<Parent> parentQuery,
      [List<String> columns = const ['*'],]) {
    return super
        .getRelationExistenceQuery(query, parentQuery, columns)
        .where(morphTypeField, '=', morphType);
  }
}

import '../../../../contracts/database/query_builder_interface.dart';
import '../../model_base/khadem_model.dart';

abstract class Relation<Related extends KhademModel<Related>, Parent> {
  /// The query builder instance.
  final QueryBuilderInterface<Related> query;

  /// The parent model instance.
  final Parent parent;

  /// The related model factory.
  final Related Function() relatedFactory;

  Relation(this.query, this.parent, this.relatedFactory);

  /// Get the results of the relationship.
  Future<dynamic> getResults();

  /// Set the base constraints on the relation query.
  void addConstraints();

  /// Set the constraints for an eager load of the relation.
  void addEagerConstraints(List<KhademModel> models);

  /// Initialize the relation on a set of models.
  List<KhademModel> initRelation(List<KhademModel> models, String relation);

  /// Match the eagerly loaded results to their parents.
  List<KhademModel> match(
    List<KhademModel> models,
    List<Related> results,
    String relation,
  );

  /// Get the query builder for the relation.
  QueryBuilderInterface<Related> getQuery() => query;

  /// Get the underlying query builder.
  QueryBuilderInterface<Related> toBase() => query;

  /// Add the constraints for a relationship count query.
  QueryBuilderInterface<Related> getRelationExistenceQuery(
    QueryBuilderInterface<Related> query,
    QueryBuilderInterface<Parent> parentQuery, [
    List<String> columns = const ['*'],
  ]);
}

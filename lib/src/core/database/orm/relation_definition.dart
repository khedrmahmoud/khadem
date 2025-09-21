import 'package:khadem/khadem.dart' show QueryBuilderInterface;

import '../model_base/khadem_model.dart';
import 'relation_type.dart';

class RelationDefinition<T extends KhademModel<T>> {
  final RelationType type;
  final String relatedTable;
  final String localKey;
  final String foreignKey;
  final T Function() factory;
  final String? pivotTable;
  final String? foreignPivotKey;
  final String? relatedPivotKey;
  final String? morphTypeField;
  final String? morphIdField;
  final Function(QueryBuilderInterface)? query;

  RelationDefinition({
    required this.type,
    required this.relatedTable,
    required this.localKey,
    required this.foreignKey,
    required this.factory,
    this.pivotTable,
    this.foreignPivotKey,
    this.relatedPivotKey,
    this.morphTypeField,
    this.morphIdField,
    this.query,
  });
}

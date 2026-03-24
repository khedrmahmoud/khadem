import 'package:khadem/contracts.dart' show QueryBuilderInterface;

class With {
  /// The name of the relation to be loaded.
  final String relation;

  /// A list of nested relations to be loaded within this relation.
  final List<dynamic> nested;

  /// Whether to paginate the results of this relation.
  final bool paginate;

  /// The page number to load (if pagination is enabled).
  final int? page;

  /// The number of items per page (if pagination is enabled).
  final int? perPage;

  /// An optional custom query function to modify the query for this relation.
  final Function(QueryBuilderInterface)? query;

  /// A helper class to represent eager loading specifications in a structured way.
  /// This class is used to define relations to be loaded with their nested relations and pagination settings.
  /// Example usage:
  /// ```dart
  /// With('posts',
  /// nested: [With('comments'), With('user')],
  /// paginate: true, page: 1, perPage: 10);
  /// ```
  ///
  const With(
    this.relation, {
    this.nested = const [],
    this.paginate = false,
    this.page,
    this.perPage,
    this.query,
  });
}

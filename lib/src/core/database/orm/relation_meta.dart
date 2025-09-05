class RelationMeta {
  final String key;
  final bool paginate;
  final int? page;
  final int? perPage;
  final List<dynamic> nested;
  final Function? query;

  RelationMeta({
    required this.key,
    this.paginate = false,
    this.page,
    this.perPage,
    this.nested = const [],
    this.query,
  });
}

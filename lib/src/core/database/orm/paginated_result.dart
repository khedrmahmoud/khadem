import '../model_base/khadem_model.dart';

class PaginatedResult<T> {
  final List<T> data;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  PaginatedResult({
    required this.data,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  Map<String, dynamic> toJson() => {
        'data': data is List<KhademModel>
            ? (data as List<KhademModel>)
                .map((dynamic e) => e.toJson())
                .toList()
            : data,
        'meta': {
          'total': total,
          'per_page': perPage,
          'current_page': currentPage,
          'last_page': lastPage,
        },
      };

  Future<Map<String, dynamic>> toJsonAsync() async => {
        'data': data is List<KhademModel>
            ? await Future.wait(
                (data as List<KhademModel>).map((dynamic e) => e.toJsonAsync()),
              )
            : data,
        'meta': {
          'total': total,
          'per_page': perPage,
          'current_page': currentPage,
          'last_page': lastPage,
        },
      };
}

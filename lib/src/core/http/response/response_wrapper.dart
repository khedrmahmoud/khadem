import 'response.dart';
 
/// Wraps the response and captures the response data for caching or inspection.
class ResponseWrapper extends Response {
  Map<String, dynamic>? data;

  ResponseWrapper(super.raw);

  @override
  void sendJson(Map<String, dynamic> data) {
    this.data = data;
    super.sendJson(data);
  }
}

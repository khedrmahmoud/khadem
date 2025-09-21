import 'response.dart';

/// Wraps the response and captures the response data for caching or inspection.
///
/// This wrapper extends the modular Response class and provides additional
/// functionality for capturing response data without sending it immediately.
class ResponseWrapper extends Response {
  Map<String, dynamic>? data;

  ResponseWrapper(super.raw);

  @override
  void sendJson(Map<String, dynamic> data) {
    this.data = data;
    super.sendJson(data);
  }

  /// Gets the captured response data if available.
  Map<String, dynamic>? get capturedData => data;

  /// Checks if response data has been captured.
  bool get hasCapturedData => data != null;

  /// Clears the captured data.
  void clearCapturedData() {
    data = null;
  }
}

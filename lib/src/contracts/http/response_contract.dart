/// A minimal response contract that can be backed by HTTP or Socket responses.
///
/// This exists so middleware can be shared across transports.
abstract class ResponseContract {
  bool get sent;
  int get statusCode;

  ResponseContract status(int code);
  ResponseContract setStatusCode(int code);
  ResponseContract header(String name, String value);
  ResponseContract withHeaders(Map<String, String> headers);

  ResponseContract cors({
    String? allowOrigin,
    String? allowMethods,
    String? allowHeaders,
    String? exposeHeaders,
    bool allowCredentials,
    int? maxAge,
  });

  ResponseContract security({
    bool enableHsts,
    bool enableCsp,
    bool enableXFrameOptions,
    bool enableXContentTypeOptions,
    String? cspPolicy,
  });

  void send(String text);
  void sendJson(dynamic data);
  void json(dynamic data);
  void empty();

  void problem({
    required String title,
    required int status,
    String? detail,
    String? type,
    String? instance,
    Map<String, dynamic>? extensions,
  });
}

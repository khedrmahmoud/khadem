import 'package:khadem/khadem_dart.dart' show Request, Response;

class HomeController {
  HomeController._();
  static Future index(Request req, Response res) async {
    res.sendJson({'message': 'Welcome to Khadem Dart Framework!'});
  }

  static Future welcome(Request req, Response res) async {
    await res.view('welcome');
  }

  static Future stream(Request req, Response res) async {
    await res.stream<String>(
      Stream.periodic(const Duration(milliseconds: 500), (i) => "Line $i\n")
          .take(10),
    );
  }
}

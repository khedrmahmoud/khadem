import 'dart:io';
import 'package:khadem/khadem_dart.dart' show Request, Response;

class HomeController {
  void index(Request req, Response res) {
    res.sendJson({'message': 'Welcome to Khadem Dart Framework!'});
  }

  Future welcome(Request req, Response res) async {
    res.file(File('resources/views/home/index.html'));
  }

  void stream(Request req, Response res) async {
    await res.stream<String>(
      Stream.periodic(Duration(milliseconds: 500), (i) => "Line $i\n").take(10),
    );
  }
}

import '../../core/http/request/request.dart';

class Auth {
  final Request? _request;

  Auth([this._request]);

  Map<String, dynamic>? get user => _request?.user;
  dynamic get id => _request?.userId;
  bool get check => _request?.isAuthenticated ?? false;
  bool get guest => _request?.isGuest ?? true;
}

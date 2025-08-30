import 'dart:convert';
import 'dart:math';

import '../../../application/khadem.dart';
import '../../../support/helpers/hash_helper.dart';
import '../core/auth_driver.dart';
import '../exceptions/auth_exception.dart';

class TokenAuthService implements AuthDriver {
  final String providerKey;

  TokenAuthService({required this.providerKey});

  @override
  Future<Map<String, dynamic>> attemptLogin(
      Map<String, dynamic> credentials,) async {
    final config = Khadem.config.section('auth') ?? {};
    final provider = config['providers'][providerKey];
    final table = provider['table'] as String;
    final fields = provider['fields'] as List<dynamic>;
    final query = Khadem.db.table(table);

    for (final field in fields) {
      if (credentials.containsKey(field)) {
        query.where(field as String, '=', credentials[field]);
      }
    }

    final user = await query.first();
    if (user == null) {
      throw AuthException('Invalid credentials');
    }

    // 🔐 Check password (use secure hash compare)
    if (!HashHelper.verify(credentials['password'] as String, user['password'] as String)) {
      throw AuthException('Invalid credentials');
    }

    // 🪪 Create personal access token
    final token =
        _generateSecureToken(id: user[provider['primary_key']].toString());

    await Khadem.db.table('personal_access_tokens').insert({
      'token': token,
      'tokenable_id': user[provider['primary_key']],
      'guard': providerKey,
      'created_at': DateTime.now().toIso8601String(),
    });

    return {'token': token, 'user': user};
  }

  @override
  Future<Map<String, dynamic>> verifyToken(String token) async {
    final config = Khadem.config.section('auth') ?? {};
    final provider = config['providers'][providerKey];
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;

    // 🔍 1. Find the token
    final tokenRow = await Khadem.db
        .table('personal_access_tokens')
        .where('token', '=', token)
        .first();

    if (tokenRow == null) {
      throw AuthException('Invalid token');
    }

    // 👤 2. Find the user associated with the token
    final userId = tokenRow['tokenable_id'];
    final user =
        await Khadem.db.table(table).where(primaryKey, '=', userId).first();

    if (user == null) {
      throw AuthException('$providerKey not found');
    }

    return user as Map<String, dynamic>;
  }

  @override
  Future<void> logout(String token) async {
    await Khadem.db
        .table('personal_access_tokens')
        .where('token', '=', token)
        .delete();
  }

  String _generateRandomToken([int length = 64]) {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _generateSecureToken({int length = 64, String id = ''}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return "$id|${base64UrlEncode(bytes).substring(0, length)}";
  }
}

import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../../../application/khadem.dart';
import '../core/auth_driver.dart';
import '../exceptions/auth_exception.dart';
import '../../../support/helpers/hash_helper.dart';
import 'dart:math';

class JWTAuthService implements AuthDriver {
  final String providerKey;
  late final String secret;
  late final Duration accessTokenExpiry;
  late final Duration refreshTokenExpiry;

  JWTAuthService({required this.providerKey}) {
    secret = Khadem.env.getOrDefault('JWT_SECRET', 'secret');
    accessTokenExpiry = Duration(
      minutes:
          int.parse(Khadem.env.getOrDefault('JWT_ACCESS_EXPIRY_MINUTES', '15')),
    );
    refreshTokenExpiry = Duration(
      days: int.parse(Khadem.env.getOrDefault('JWT_REFRESH_EXPIRY_DAYS', '7')),
    );
  }

  /// Attempt login, return both access and refresh tokens
  @override
  Future<Map<String, dynamic>> attemptLogin(
      Map<String, dynamic> credentials) async {
    final provider = Khadem.config.get('auth.providers')[providerKey];
    final table = provider['table'] as String;
    final fields = provider['fields'];
    final primaryKey = provider['primary_key'];

    final query = Khadem.db.table(table );

    for (final field in fields as List<String>) {
      if (credentials.containsKey(field)) {
        query.where(field, '=', credentials[field]);
      }
    }

    final user = await query.first();
    if (user == null) {
      throw AuthException('Invalid credentials');
    }

    if (!HashHelper.verify(credentials['password'] as String, user['password'] as String)) {
      throw AuthException('Invalid credentials');
    }

    final payload = {
      'id': user[primaryKey],
      'guard': providerKey,
    };

    final accessToken = JWT(payload).sign(
      SecretKey(secret),
      expiresIn: accessTokenExpiry,
    );

    final refreshToken = _generateRefreshToken();

    await Khadem.db.table('personal_access_tokens').insert({
      'token': refreshToken,
      'tokenable_id': user[primaryKey],
      'guard': providerKey,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(refreshTokenExpiry).toIso8601String(),
    });

    return {
      "user": user,
      "token": {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': 'Bearer',
        'expires_in_minutes': accessTokenExpiry.inMinutes.toString(),
        'refresh_expires_in_days': refreshTokenExpiry.inDays.toString(),
      }
    };
  }

  /// Verify JWT token and return the payload
  @override
  Future<Map<String, dynamic>> verifyToken(String token) async {
    final config = Khadem.config.section('auth') ?? {};
    final provider = config['providers'][providerKey];
    final table = provider['table'] as String;
    final primaryKey = provider['primary_key'] as String;

    try {
      final jwt = JWT.verify(token, SecretKey(secret));
      final payload = jwt.payload;
      if (payload == null) {
        throw AuthException('Invalid token');
      }

      // 👤 2. Find the user associated with the token
      final userId = payload['id'];
      final user =
          await Khadem.db.table(table).where(primaryKey, '=', userId).first();

      if (user == null) {
        throw AuthException('$providerKey not found');
      }

      return user as Map<String, dynamic>;
    } catch (e) {
      throw AuthException('Invalid or expired token');
    }
  }

  /// Refresh access token using a valid refresh token
  Future<String> refreshAccessToken(String refreshToken) async {
    final tokenRow = await Khadem.db
        .table('personal_access_tokens')
        .where('token', '=', refreshToken)
        .first();

    if (tokenRow == null) {
      throw AuthException('Invalid refresh token');
    }

    final expiresAt = DateTime.parse(tokenRow['expires_at'] as String);
    if (DateTime.now().isAfter(expiresAt)) {
      throw AuthException('Refresh token expired');
    }

    final userId = tokenRow['tokenable_id'];

    final payload = {
      'id': userId,
      'guard': providerKey,
    };

    return JWT(payload).sign(
      SecretKey(secret),
      expiresIn: accessTokenExpiry,
    );
  }

  @override
  Future<void> logout(String token) async {
    await Khadem.db
        .table('personal_access_tokens')
        .where('token', '=', token)
        .delete();
  }

  /// Utility to generate secure refresh token
  String _generateRefreshToken([int length = 64]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).substring(0, length);
  }
}
